package com.ecommerce.controllers;

import com.ecommerce.model.DbConnection;
import jakarta.servlet.RequestDispatcher;
import java.io.IOException;
import java.io.PrintWriter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.sql.*;

@WebServlet("/adminLogin")
public class AdminLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        String username = req.getParameter("adminName");
        String pass = req.getParameter("adminPass");
        PrintWriter out = resp.getWriter();
        
        try {
            Connection conn = DbConnection.getConnection();
            String select_admin_query = "SELECT * FROM register WHERE name=? AND password=? AND role='admin'";
            PreparedStatement ps = conn.prepareStatement(select_admin_query);
            ps.setString(1, username);
            ps.setString(2, pass);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                HttpSession session = req.getSession();
                session.setAttribute("admin", username);

                resp.sendRedirect(req.getContextPath() + "/views/admin/adminhome.jsp");
                System.out.println("admin login successfully");
            } else {
              
                resp.sendRedirect(req.getContextPath() + "/views/admin/adminlogin.jsp?error=invalid");
                System.out.println("Failed To Login Admin!!");
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
