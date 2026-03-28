package com.ecommerce.controllers;

import com.ecommerce.model.DbConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/track")
public class TrackingServlet extends HttpServlet {

    // ── User site origin allowed to post tracking data ─────────────
    private static final String ALLOWED_ORIGIN = "https://greencart-e-commerce-1.onrender.com";

    // ── Add CORS headers to every response ─────────────────────────
    private void addCorsHeaders(HttpServletResponse resp) {
        resp.setHeader("Access-Control-Allow-Origin",      ALLOWED_ORIGIN);
        resp.setHeader("Access-Control-Allow-Methods",     "POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers",     "Content-Type");
        resp.setHeader("Access-Control-Allow-Credentials", "true");
    }

    // ── Handle preflight OPTIONS request from browser ───────────────
    @Override
    protected void doOptions(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        addCorsHeaders(resp);
        resp.setStatus(HttpServletResponse.SC_OK);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // CORS headers must be first on every POST
        addCorsHeaders(resp);

        resp.setContentType("text/plain");
        resp.setCharacterEncoding("UTF-8");

        String action     = req.getParameter("action");
        String eventType  = req.getParameter("eventType");
        String eventData  = req.getParameter("eventData");
        String pageUrl    = req.getParameter("pageUrl");
        String timeOnPage = req.getParameter("timeOnPage");
        String deviceType = req.getParameter("deviceType");

        HttpSession session  = req.getSession();
        String sessionId     = session.getId();
        Integer userId       = (Integer) session.getAttribute("userId");
        String userEmail     = (String)  session.getAttribute("userEmail");
        String ipAddress     = req.getRemoteAddr();

        Connection conn = null;
        try {
            conn = DbConnection.getConnection();

            // ── SESSION START ──────────────────────────────────────────
            if ("session_start".equals(action)) {
                PreparedStatement checkPs = conn.prepareStatement(
                        "SELECT id FROM user_sessions WHERE session_id=?");
                checkPs.setString(1, sessionId);
                ResultSet checkRs = checkPs.executeQuery();
                boolean exists = checkRs.next();
                checkRs.close(); checkPs.close();

                if (!exists) {
                    PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO user_sessions (session_id, user_id, user_email, device_type, ip_address) " +
                                    "VALUES (?, ?, ?, ?, ?)");
                    ps.setString(1, sessionId);
                    ps.setObject(2, userId);
                    ps.setString(3, userEmail != null ? userEmail : "Guest");
                    ps.setString(4, deviceType != null ? deviceType : "Unknown");
                    ps.setString(5, ipAddress);
                    ps.executeUpdate();
                    ps.close();
                }
            }

            // ── SESSION END ────────────────────────────────────────────
            else if ("session_end".equals(action)) {
                int duration = 0;
                try { duration = Integer.parseInt(timeOnPage); } catch (Exception e) {}

                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE user_sessions SET ended_at=NOW(), duration_seconds=? WHERE session_id=?");
                ps.setInt(1, duration);
                ps.setString(2, sessionId);
                ps.executeUpdate();
                ps.close();
            }

            // ── EVENT TRACKING ─────────────────────────────────────────
            else if ("event".equals(action)) {
                int timeInt = 0;
                try { timeInt = Integer.parseInt(timeOnPage); } catch (Exception e) {}

                PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO user_events (session_id, event_type, event_data, page_url, time_on_page) " +
                                "VALUES (?, ?, ?, ?, ?)");
                ps.setString(1, sessionId);
                ps.setString(2, eventType  != null ? eventType  : "unknown");
                ps.setString(3, eventData  != null ? eventData  : "");
                ps.setString(4, pageUrl    != null ? pageUrl    : "");
                ps.setInt(5, timeInt);
                ps.executeUpdate();
                ps.close();
            }

            resp.getWriter().write("ok");

        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().write("error");
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}