<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="org.silix.the9ull.microbit.control.GetInfoBeanRemote"%>
<%@page import="org.silix.the9ull.microbit.controlinterface.EJBUtils"%>
<%@page import="javax.naming.Context"%>
<%@page import="javax.naming.InitialContext"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Micro Bi(t). Home</title>
</head>
<%!String ip;%>
<%!long nusers;%>
<%!double usd, eur;%>
<%!GetInfoBeanRemote gi;%>
<body>
<jsp:include page="header.jsp" />
<%
	//GetInfoRemote gi = EJBUtils.getGetInfo();

//System.out.println(gi.valueBtcEur());
//System.out.println(gi.valueBtcUsd());
//System.out.println(gi.numberOfUsers());

ip = request.getRemoteAddr();
//gi = EJBUtils.getGetInfo();
//nusers = gi.numberOfUsers();

Context context = new InitialContext(); 
GetInfoBeanRemote gi = (GetInfoBeanRemote)context.lookup("java:global/Microbi25/GetInfoBean");

usd = gi.valueBtcUsd();
eur = gi.valueBtcEur();
%>
<!--Your IP address is <%= ip %> but... who cares?<br/><br/><br/>-->

<div align="left">
	<a href="register.jsp">Register</a> 1BTC = <%= usd %>USD; 1BTC = <%= eur %>EUR; Users = <%= nusers %>
	
	<br />
	<form name="login" action="login.jsp" method="POST">
		<input type="text" name="id" value="id or deposit address" onclick="this.form.elements[0].value = ''" />
		<input type="password" name="password" value="***" onclick="this.form.elements[1].value = ''" />
		<input type="submit" value="Go" style="visibility:hidden" />
	</form>
</div>

</body>
</html>