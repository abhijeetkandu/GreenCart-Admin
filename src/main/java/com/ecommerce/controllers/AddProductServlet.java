package com.ecommerce.controllers;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.ecommerce.model.DbConnection;
import java.io.IOException;
import java.io.InputStream;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Map;

@WebServlet("/addProduct")
@MultipartConfig
public class AddProductServlet extends HttpServlet {

    // Cloudinary config
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

        String pname      = req.getParameter("name");
        String priceStr   = req.getParameter("price");
        String quantityStr = req.getParameter("quantity");

        double price    = 0;
        int    quantity = 0;

        if (priceStr != null && !priceStr.isEmpty())
            price = Double.parseDouble(priceStr);
        if (quantityStr != null && !quantityStr.isEmpty())
            quantity = Integer.parseInt(quantityStr);

        try {
            Connection conn = DbConnection.getConnection();

            // Insert product
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO products(name, price, quantity) VALUES (?, ?, ?)",
                PreparedStatement.RETURN_GENERATED_KEYS);
            ps.setString(1, pname);
            ps.setDouble(2, price);
            ps.setInt(3, quantity);
            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            int productId = 0;
            if (rs.next()) productId = rs.getInt(1);

            // Upload images to Cloudinary
            PreparedStatement psImg = conn.prepareStatement(
                "INSERT INTO product_images(product_id, image_url) VALUES (?, ?)");

            for (int i = 1; i <= 8; i++) {
                Part filePart = req.getPart("image" + i);
                if (filePart != null && filePart.getSize() > 0) {
                    // Upload to Cloudinary using input stream
                    InputStream fileStream = filePart.getInputStream();
                    Map uploadResult = cloudinary.uploader().upload(
                        fileStream.readAllBytes(),
                        ObjectUtils.asMap(
                            "folder", "greencart/products",
                            "public_id", "product_" + productId + "_" + i
                        )
                    );

                    // Get the permanent Cloudinary URL
                    String imageUrl = (String) uploadResult.get("secure_url");

                    psImg.setInt(1, productId);
                    psImg.setString(2, imageUrl);
                    psImg.executeUpdate();
                }
            }

            resp.sendRedirect(req.getContextPath() + "/views/admin/adminhome.jsp");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
