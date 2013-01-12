<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Collections" %>
<%@page import="java.util.List" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Micro Bi(t). Home</title>
</head>
<body>
<jsp:include page="header.jsp" />

<jsp:useBean id="login" scope="session" class="org.silix.the9ull.microbit.controlinterface.LoginJB" />
<jsp:useBean id="info" scope="application" class="org.silix.the9ull.microbit.controlinterface.GetInfoJB" />

<div align="left">
	<%
	if(!login.isLogged()){
	%>
	<a href="register.jsp">Register</a>
	<% } %>
	1BTC = <jsp:getProperty name="info" property="usd" /> USD;
	1BTC = <jsp:getProperty name="info" property="eur" /> EUR;
	Users = <jsp:getProperty name="info" property="nusers" /> 
	
	<br />
	<%
	if(login.isLogged()){
	%>
	User id: <jsp:getProperty name="login" property="id" />. Fund: <jsp:getProperty name="login" property="fund" />. <a href="index.jsp?contacts">contacts</a> <a href="logout.jsp">logout</a><br />
	Deposit address: <jsp:getProperty name="login" property="address" /><br />
	<%
		List<String> l = Collections.list((Enumeration<String>)request.getParameterNames());
		if(l.contains("contacts")){
	%>
		<jsp:setProperty name="login" property="*" />
	<%
		if(request!=null && request.getParameter("newAlias")!=null){
			// new contact!
			login.addNewContact();
		}
	%>
		<jsp:getProperty name="login" property="contactsTable" /> <br />
	<%
	if(request!=null && request.getParameter("newAlias")!=null) {
		if(login.isAddedContact()) {
	%>Contact inserted<br /><%
		} else {
	%><font color="red">Contact not inserted</font><br /><%		
		}
	}
	%>
		<jsp:include page="newcontact.jsp" />
	<%
		}
	} else {
	%>
	<form name="login" action="login.jsp" method="POST">
		<input type="text" name="id" value="id or deposit address" onclick="this.form.elements[0].value = ''" />
		<input type="password" name="password" value="***" onclick="this.form.elements[1].value = ''" />
		<input type="submit" value="Go" style="visibility:hidden" />
	</form>
	<% } %>
</div>

</body>
</html>