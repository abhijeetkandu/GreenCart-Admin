package com.ecommerce.model;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DbConnection {

    public static Connection getConnection() throws ClassNotFoundException, SQLException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        String url      = System.getenv("DB_URL");
        String username = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");
        Connection conn = DriverManager.getConnection(url, username, password);
        System.out.println("Connected Successfully ✅");
        return conn;
    }

    public static void main(String[] args) throws Exception {
        getConnection();
    }
}
