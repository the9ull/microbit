<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Collections" %>
<%@page import="java.util.List" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Micro Bi(t). Home</title>
<style TYPE="text/css">
table.collapse {
  border-collapse:collapse;
}
td.border {
  border-style:solid; 
  border-width:1px; 
  border-color:#333333; 
  padding:3px;
}
th.border {
  border-style:solid; 
  border-width:1px; 
  border-color:#333333; 
  padding:1px;
}
</style>
</head>
<body>
<jsp:include page="header.jsp" />

<jsp:useBean id="login" scope="session" class="org.silix.the9ull.microbit.controlinterface.LoginJB" />
<jsp:useBean id="info" scope="application" class="org.silix.the9ull.microbit.controlinterface.GetInfoJB" />

<jsp:setProperty name="login" property="*" />

<div align="left">
	<%
	if(!login.isLogged()){
	%>
	<a href="register.jsp">Register</a><br />
	<jsp:getProperty name="login" property="strError" />
	<% } %>
	1BTC = <jsp:getProperty name="info" property="usd" /> USD;
	1BTC = <jsp:getProperty name="info" property="eur" /> EUR;
	Users = <jsp:getProperty name="info" property="nusers" /> 
	
	<br />
	<%
	if(login.isLogged()){
		List<String> parameters = Collections.list((Enumeration<String>)request.getParameterNames());
		if(parameters.contains("sendTo")) {
			//Senda money before load user Fund
			login.sendTo();
		}
	%>
	User id: <jsp:getProperty name="login" property="id" />.
	Fund: <jsp:getProperty name="login" property="fund" />.
	
	<a href="index.jsp?history=30">history</a>
	<% out.print(parameters.contains("history")
			&& request.getParameter("history").equals("30") ? "<a href=\"index.jsp?history\">full history</a>" : ""); %>
	<a href="logout.jsp">logout</a><br />
	Deposit address: <jsp:getProperty name="login" property="address" /><br /><br />
	<jsp:getProperty name="login" property="strError" />
	<%
		if(!parameters.contains("history")){
			if(parameters.contains("newContact") || parameters.contains("restoreContact")){
				// new contact!
				if(login.isContactAddressValid()) {
					login.addNewContact();
					if(login.isAddedContact()) {
						if(parameters.contains("newContact")) {
	%>Contact inserted<br /><%
						} else {
	%>Contact restored<br /><%					
						}
					} else {
						if(parameters.contains("newContact")) {
	%><font color="red">Contact not inserted</font><br /><%
						} else {
	%><font color="red">Contact not restored</font><br /><%					
						}
	%><jsp:getProperty name="login" property="strError" /><%
					}
				} else {
	%><font color="red">The address is not valid</font><br /><%				
				}
			} else if(parameters.contains("deleteContact")) {
				login.removeContact();
				if(login.isRemovedContact()) {
	%>Contact removed <jsp:getProperty name="login" property="restoreForm" /><br /><%				
				} else {
	%><font color="red">Contact not removed</font><br />
	<jsp:getProperty name="login" property="strError" /><%				
				}
			} else if(parameters.contains("sendTo")) {
				if(login.isSentTo()){
	%><jsp:getProperty name="login" property="howMuch" />
	sent to <jsp:getProperty name="login" property="alias" />
	(fee: <jsp:getProperty name="login" property="fee" />)<br /><%
				} else {
	%><font color="red">Transaction failed</font><br /><%				
				}
			}
	%>
		<jsp:getProperty name="login" property="contactsTable" /><br />
		<jsp:getProperty name="login" property="strError" />
		<jsp:include page="newcontact.jsp" />
	<%
		} else {
			// → parameters.contains("history")
	%><jsp:include page="history.jsp" /><%
		}
	} else {
	%>
	<form name="login" action="login.jsp" method="POST">
		<input type="text" name="id" value="id or deposit address" onclick="this.form.elements[0].value = ''" />
		<input type="password" name="password" value="***" onclick="this.form.elements[1].value = ''" />
		<input type="submit" value="Go" style="visibility:hidden" />
	</form>
	<%
	}
	%>
</div>

</body>
</html>