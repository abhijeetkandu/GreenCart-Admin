package com.ecommerce.controllers;

import com.ecommerce.model.DbConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/updateOrderStatus")
public class Updateorderstatusservlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Admin guard
        String admin = null;
        HttpSession session = request.getSession(false);
        if (session != null) {
            admin = (String) session.getAttribute("admin");
        }
        if (admin == null) {
            response.sendRedirect(request.getContextPath() + "/views/adminlogin.jsp");
            return;
        }

        String orderIdStr = request.getParameter("orderId");
        String newStatus  = request.getParameter("status");

        if (orderIdStr == null || newStatus == null || orderIdStr.isBlank() || newStatus.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/views/adminorders.jsp?error=invalid");
            return;
        }

        // Validate status value
        if (!newStatus.matches("Pending|Processing|Delivered|Cancelled")) {
            response.sendRedirect(request.getContextPath() + "/views/adminorders.jsp?error=badstatus");
            return;
        }

        try {
            int orderId = Integer.parseInt(orderIdStr);
            Connection conn = DbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                    "UPDATE orders SET status = ? WHERE id = ?");
            ps.setString(1, newStatus);
            ps.setInt(2, orderId);
            ps.executeUpdate();
            ps.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/views/adminorders.jsp?error=db");
            return;
        }

        // Preserve filter param
        String ref = request.getHeader("Referer");
        if (ref != null && ref.contains("status=")) {
            response.sendRedirect(ref);
        } else {
            response.sendRedirect(request.getContextPath() + "/views/adminorders.jsp?updated=" + orderIdStr);
        }
    }
}