package com.ecommerce.controllers;

import com.ecommerce.model.DbConnection;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import java.io.*;
import java.sql.*;

@WebServlet("/deleteProduct")
public class DeleteProductServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int productId = Integer.parseInt(request.getParameter("productId"));

        Connection conn = null;
        try {
            conn = DbConnection.getConnection();

            // 1. Delete images first (child table)
            PreparedStatement delImg = conn.prepareStatement(
                "DELETE FROM product_images WHERE product_id=?");
            delImg.setInt(1, productId);
            delImg.executeUpdate();
            delImg.close();

            // 2. Delete product
            PreparedStatement delProd = conn.prepareStatement(
                "DELETE FROM products WHERE id=?");
            delProd.setInt(1, productId);
            delProd.executeUpdate();
            delProd.close();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }

        response.sendRedirect(request.getContextPath() + "/views/admin/adminhome.jsp");
    }
}
