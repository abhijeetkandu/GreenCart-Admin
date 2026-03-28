package com.ecommerce.controllers;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.ecommerce.model.DbConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Map;

@WebServlet("/updateProduct")
@MultipartConfig
public class UpdateProductServlet extends HttpServlet {

    private Cloudinary cloudinary;

    @Override
    public void init() {
        cloudinary = new Cloudinary(ObjectUtils.asMap(
            "cloud_name", "dn7bbmpgd",
            "api_key",    "447983828759695",
            "api_secret", "9KUqkdYirvK0Ic5ZD57U1h_hb0Q"
        ));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        int    productId = Integer.parseInt(req.getParameter("productId"));
        String name      = req.getParameter("name");
        double price     = Double.parseDouble(req.getParameter("price"));
        int    quantity  = Integer.parseInt(req.getParameter("quantity"));

        Connection conn = null;
        try {
            conn = DbConnection.getConnection();

            // 1. Update name, price, quantity
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE products SET name=?, price=?, quantity=? WHERE id=?");
            ps.setString(1, name);
            ps.setDouble(2, price);
            ps.setInt(3, quantity);
            ps.setInt(4, productId);
            ps.executeUpdate();
            ps.close();

            // 2. Check if any new image uploaded
            boolean anyImage = false;
            for (int i = 1; i <= 8; i++) {
                Part p = req.getPart("image" + i);
                if (p != null && p.getSize() > 0) { anyImage = true; break; }
            }

            // 3. If new images → delete old DB records → upload new to Cloudinary
            if (anyImage) {
                PreparedStatement delImg = conn.prepareStatement(
                    "DELETE FROM product_images WHERE product_id=?");
                delImg.setInt(1, productId);
                delImg.executeUpdate();
                delImg.close();

                PreparedStatement psImg = conn.prepareStatement(
                    "INSERT INTO product_images(product_id, image_url) VALUES (?, ?)");

                for (int i = 1; i <= 8; i++) {
                    Part filePart = req.getPart("image" + i);
                    if (filePart != null && filePart.getSize() > 0) {
                        InputStream fileStream = filePart.getInputStream();
                        Map uploadResult = cloudinary.uploader().upload(
                            fileStream.readAllBytes(),
                            ObjectUtils.asMap(
                                "folder",    "greencart/products",
                                "public_id", "product_" + productId + "_" + i
                            )
                        );
                        String imageUrl = (String) uploadResult.get("secure_url");

                        psImg.setInt(1, productId);
                        psImg.setString(2, imageUrl);
                        psImg.executeUpdate();
                    }
                }
                psImg.close();
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }

        resp.sendRedirect(req.getContextPath() + "/views/admin/adminhome.jsp");
    }
}
