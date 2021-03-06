package org.silix.the9ull.microbit.control;

import java.io.IOException;
import java.math.BigDecimal;
import java.rmi.RemoteException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.ejb.EJBHome;
import javax.ejb.EJBObject;
import javax.ejb.Handle;
import javax.ejb.PostActivate;
import javax.ejb.PrePassivate;
import javax.ejb.Remove;
import javax.ejb.RemoveException;
import javax.ejb.Stateful;
import javax.inject.Named;

import org.hibernate.Query;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.silix.the9ull.microbit.model.ContactP;
import org.silix.the9ull.microbit.model.HistoryP;
import org.silix.the9ull.microbit.model.PersistenceUtility;
import org.silix.the9ull.microbit.model.SingletonSessionFactory;
import org.silix.the9ull.microbit.model.Tx;
import org.silix.the9ull.microbit.model.UserP;

import sun.reflect.generics.reflectiveObjects.NotImplementedException;

@Stateful
@Named
public class UserBean implements UserBeanRemote {

	private Session session;
	private UserP user;
	private Transactions transactions;
	
	@Override
	public EJBHome getEJBHome() throws RemoteException {
		throw new NotImplementedException();
	}

	@Override
	public Handle getHandle() throws RemoteException {
		throw new NotImplementedException();
	}

	@Override
	public Object getPrimaryKey() throws RemoteException {
		throw new NotImplementedException();
	}

	@Override
	public boolean isIdentical(EJBObject arg0) throws RemoteException {
		UserBean u = (UserBean) arg0;
		return this.getUser().equals(u.getUser());
	}

	@Override
	public void remove() throws RemoteException, RemoveException {
		System.out.println("Remove the EJB UserBean");
	}

	@PostConstruct
	@PostActivate
	public void creation() {
		System.out.println("UserBean: creation && attivation");
		session = SingletonSessionFactory.getSession();
		try {
			transactions = Transactions.getInstance();
		} catch (IOException e) {
			System.out.println("UserBean: Transactions obj not loaded");
			e.printStackTrace();
		} catch (BitcoinConnectionException e) {
			e.printStackTrace();
		}
	}
	@PrePassivate
	@PreDestroy
	public void destruction() {
		System.out.println("UserBean: destruction && passivation");
		SingletonSessionFactory.closeSession(session);
		session = null;
		transactions = null;
	}

	// User API

	@Override
	public boolean login(int id, String password) throws RemoteException {
		user = (UserP) session.get(UserP.class,id);
		
		if(user==null)
			return false;
		return user.getPassword().equals(SHA1.HMAC_digest(""+id,password));
	}

	@Override
	@Remove
	public void logout() throws RemoteException {
		user = null;
	}

	@Override
	public BigDecimal getFund() throws RemoteException {
		// Login check
		if(user==null)
			return null;
		Transaction htx = session.beginTransaction();
		try {
			transactions.updatefunds(false, session);
		} catch (BitcoinConnectionException e) {
			htx.rollback();
			return null;
		}
		htx.commit();
		return user.getFund();
	}
	
	public void setFund(BigDecimal fund) throws RemoteException {
		System.out.println("UserBean: you can't create money");
		assert(false);
	}

	@Override
	public Set<ContactP> getContacts() throws RemoteException {
		if(user==null)
			return null;
		return user.getContacts();
	}

	public UserP getUser() {
		return user;
	}

	@Override
	public boolean newContact(String alias, String address)
			throws RemoteException {
		
		if(user==null)
			return false;
		Transaction tx = session.beginTransaction();
		ContactP c = new ContactP();
		c.setUser(getUser());
		c.setAlias(alias);
		ContactP old = (ContactP) session.get(ContactP.class, c);
		if(old!=null) {
			tx.rollback();
			return false;
		}
		c.setAddress(address);
		System.out.println("New contact: "+c.getAlias());
		//Add to both, session and runtime contacts
		session.save(c); // And what's happen with existing contacts? 
		user.getContacts().add(c);
		tx.commit();
		return true;
	}

	@Override
	public boolean removeContact(String alias) throws RemoteException {
		if(user==null)
			return false;
		
		Transaction tx = session.beginTransaction();
		ContactP c = new ContactP();
		c.setUser(getUser());
		c.setAlias(alias);
		c = (ContactP) session.get(ContactP.class, c);
		if(c==null) {
			tx.rollback();
			System.out.println("Contact not deleted: "+alias);
			return false;
		}
		System.out.println("Delete contact: "+alias);
		//Add to both, session and runtime contacts
		
		session.delete(c); 
		user.getContacts().remove(c);
		tx.commit();
		return true;
	}
	
	@Override
	public boolean isAddressValid(String address) throws java.rmi.RemoteException {
		try {
			if(transactions.isAddressValid(address)){
				return true;
			}
		} catch (BitcoinConnectionException e1) {
			throw new RemoteException("Bitcoin connection error");
		}
		try {
			int id = new Integer(address);
			if(id != user.getId() && session.get(UserP.class, id)!=null) {
				return true;
			}
		} catch(NumberFormatException e) {}
		
		return false; 
	}

	@Override
	public Tx sendTo(String address, BigDecimal howMuch) throws RemoteException {
		int toUserId = 0;
		Tx tx;
		System.out.println("UserBean: sendTo "+address+" "+howMuch);
		if(howMuch.compareTo(new BigDecimal(0))<=0) {
			System.out.println("howMuch<=0");
			tx = new Tx();
			tx.setStrError("Set the amount of the transaction");
			return tx;
		}
		// Is alias an user id?
		
		UserP toUser;
		
		//Assumption 1: address of a user
		Transaction htx = session.beginTransaction();
		Query q = session.createQuery("from UserP usr where usr.deposit_address='"+address+"'");
		@SuppressWarnings("unchecked")
		List<UserP> l = (List<UserP>) q.list();
		if(l.size()>0)
			toUserId = l.get(0).getId();
		else {
			try {
				toUserId = new Integer(address);
			} catch(NumberFormatException e) {}
		}
		
		if(toUserId>0) {
			// Transaction to User
			
			if(toUserId == user.getId()){
				htx.rollback();
				return null;
			}

			System.out.println("UserBean: User transaction 1.");
			toUser = (UserP) session.get(UserP.class, toUserId);
			if(toUser==null) {
				System.out.println("UserBean: User transaction 2.");
				htx.rollback();
				return null;
			}
			 
			if(transactions.sendtouser(user, toUser, howMuch, session)){
				
				tx = new Tx();
				System.out.println("User transaction 3.");
				String internalFee = PersistenceUtility.dictGet("internalfee", session);
				if(internalFee!=null) {
					System.out.println("User transaction 4.");
					tx.setFee(new BigDecimal(internalFee));
				}
				System.out.println("UserBean: to user "+tx);
				htx.commit();
				return tx;	
			} else {
				System.out.println("User transaction 5.");
				htx.rollback();
				return null;
			}
		} else {
			// Transaction to address
			
			System.out.println("UserBean: transaction");
			try {
				tx = transactions.sendtoaddress(user, address, howMuch, session);
				htx.commit();
			} catch (BitcoinConnectionException e) {
				htx.rollback();
				tx = new Tx();
				tx.setStrError("Bitcoin connection error");
			}
			System.out.println("UserBean: to address » "+tx);
			return tx;
		}
	}

	@SuppressWarnings("unchecked")
	@Override
	public Set<HistoryP> getHistory(int fromRow, int toRow) throws RemoteException {

		Query q = session.createQuery("from HistoryP h where h.from="+user.getId()+" or h.to="+user.getId()+" order by h.when desc");
		if(toRow>0) {
			q.setFirstResult(fromRow);
			q.setMaxResults(toRow);
		}
		// orderb by <field> desc
		return new HashSet<HistoryP>((List<HistoryP>)q.list());
	}	
}
