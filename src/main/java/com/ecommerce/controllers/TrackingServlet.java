package com.ecommerce.controllers;

import com.ecommerce.model.DbConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/track")
public class TrackingServlet extends HttpServlet {

    // ✅ Allow your user website
    private static final String ALLOWED_ORIGIN = "https://greencart-e-commerce-1.onrender.com";

    // ✅ CORS headers
    private void addCorsHeaders(HttpServletResponse resp) {
        resp.setHeader("Access-Control-Allow-Origin", ALLOWED_ORIGIN);
        resp.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers", "Content-Type");
        resp.setHeader("Access-Control-Allow-Credentials", "true");
    }

    // ✅ Preflight request
    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        addCorsHeaders(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        addCorsHeaders(resp);

        resp.setContentType("text/plain");
        resp.setCharacterEncoding("UTF-8");

        // 📥 Parameters
        String action     = req.getParameter("action");
        String eventType  = req.getParameter("eventType");
        String eventData  = req.getParameter("eventData");
        String pageUrl    = req.getParameter("pageUrl");
        String timeOnPage = req.getParameter("timeOnPage");
        String deviceType = req.getParameter("deviceType");

        // 🔥 FIX: Use frontend sessionId (VERY IMPORTANT)
        String sessionId = req.getParameter("sessionId");
        if (sessionId == null || sessionId.isEmpty()) {
            sessionId = req.getSession().getId(); // fallback
        }

        // Optional user info
        HttpSession session = req.getSession(false);
        Integer userId = null;
        String userEmail = "Guest";

        if (session != null) {
            userId = (Integer) session.getAttribute("userId");
            String email = (String) session.getAttribute("userEmail");
            if (email != null) userEmail = email;
        }

        String ipAddress = req.getRemoteAddr();

        Connection conn = null;

        try {
            conn = DbConnection.getConnection();

            // ───────── SESSION START ─────────
            if ("session_start".equals(action)) {

                PreparedStatement checkPs = conn.prepareStatement(
                        "SELECT id FROM user_sessions WHERE session_id=?");
                checkPs.setString(1, sessionId);
                ResultSet rs = checkPs.executeQuery();

                boolean exists = rs.next();
                rs.close();
                checkPs.close();

                if (!exists) {
                    PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO user_sessions (session_id, user_id, user_email, device_type, ip_address, started_at) " +
                                    "VALUES (?, ?, ?, ?, ?, NOW())");

                    ps.setString(1, sessionId);
                    ps.setObject(2, userId);
                    ps.setString(3, userEmail);
                    ps.setString(4, deviceType != null ? deviceType : "Unknown");
                    ps.setString(5, ipAddress);

                    ps.executeUpdate();
                    ps.close();
                }
            }

            // ───────── SESSION END ─────────
            else if ("session_end".equals(action)) {

                int duration = 0;
                try {
                    duration = Integer.parseInt(timeOnPage);
                } catch (Exception ignored) {}

                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE user_sessions SET ended_at=NOW(), duration_seconds=? WHERE session_id=?");

                ps.setInt(1, duration);
                ps.setString(2, sessionId);

                ps.executeUpdate();
                ps.close();
            }

            // ───────── EVENT TRACKING ─────────
            else if ("event".equals(action)) {

                int timeInt = 0;
                try {
                    timeInt = Integer.parseInt(timeOnPage);
                } catch (Exception ignored) {}

                PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO user_events (session_id, event_type, event_data, page_url, time_on_page) " +
                                "VALUES (?, ?, ?, ?, ?)");

                ps.setString(1, sessionId);
                ps.setString(2, eventType != null ? eventType : "unknown");
                ps.setString(3, eventData != null ? eventData : "");
                ps.setString(4, pageUrl != null ? pageUrl : "");
                ps.setInt(5, timeInt);

                ps.executeUpdate();
                ps.close();
            }

            resp.getWriter().write("ok");

        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().write("error");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignored) {}
        }
    }
}