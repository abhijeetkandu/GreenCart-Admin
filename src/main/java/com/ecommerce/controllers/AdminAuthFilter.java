package com.ecommerce.controllers;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class AdminAuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        HttpSession session = req.getSession(false);

        String uri = req.getRequestURI();

        // Always allow login page and login POST request
        boolean isLoginPage = uri.contains("adminlogin.jsp") ||
                uri.contains("adminLogin");

        boolean isLoggedIn = session != null &&
                session.getAttribute("admin") != null;

        if (isLoginPage || isLoggedIn) {
            chain.doFilter(request, response);
        } else {
            res.sendRedirect(req.getContextPath() + "/views/admin/adminlogin.jsp");
        }
    }
}