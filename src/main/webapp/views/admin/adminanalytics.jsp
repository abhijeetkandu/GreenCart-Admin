<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/admin/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();
    PreparedStatement ps;
    ResultSet rs;

    // ── Sessions Today ──
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions WHERE DATE(started_at)=CURDATE()");
    rs = ps.executeQuery();
    int todaySessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Total Sessions ──
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions");
    rs = ps.executeQuery();
    int totalSessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Total Events ──
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events");
    rs = ps.executeQuery();
    int totalEvents = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Orders ──
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='order_completed'");
    rs = ps.executeQuery();
    int totalOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Pending Orders ──
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    int pendingOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Device Types ──
    ps = conn.prepareStatement("SELECT IFNULL(device_type,'Unknown'), COUNT(*) FROM user_sessions GROUP BY device_type");
    rs = ps.executeQuery();
    Map<String,Integer> deviceMap = new LinkedHashMap<>();
    while(rs.next()){
        deviceMap.put(rs.getString(1), rs.getInt(2));
    }
    rs.close(); ps.close();

    // ── Top Pages ──
    ps = conn.prepareStatement("SELECT page_url, COUNT(*) FROM user_events GROUP BY page_url ORDER BY COUNT(*) DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while(rs.next()){
        topPages.add(new String[]{rs.getString(1), String.valueOf(rs.getInt(2))});
    }
    rs.close(); ps.close();

    // ── Top Products ──
    ps = conn.prepareStatement("SELECT event_data, COUNT(*) FROM user_events WHERE event_type='product_click' GROUP BY event_data ORDER BY COUNT(*) DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topProducts = new ArrayList<>();
    while(rs.next()){
        topProducts.add(new String[]{rs.getString(1), String.valueOf(rs.getInt(2))});
    }
    rs.close(); ps.close();

    // ── Top Cart ──
    ps = conn.prepareStatement("SELECT event_data, COUNT(*) FROM user_events WHERE event_type='add_to_cart' GROUP BY event_data ORDER BY COUNT(*) DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topCart = new ArrayList<>();
    while(rs.next()){
        topCart.add(new String[]{rs.getString(1), String.valueOf(rs.getInt(2))});
    }
    rs.close(); ps.close();

    // ── Avg Time ──
    ps = conn.prepareStatement("SELECT AVG(time_on_page) FROM user_events WHERE event_type='time_spent'");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    // ── Conversion Funnel ──
    int views=0, clicks=0, cart=0, orders=0;

    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='page_view'");
    rs = ps.executeQuery();
    if(rs.next()) views = rs.getInt(1);
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='product_click'");
    rs = ps.executeQuery();
    if(rs.next()) clicks = rs.getInt(1);
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='add_to_cart'");
    rs = ps.executeQuery();
    if(rs.next()) cart = rs.getInt(1);
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='order_completed'");
    rs = ps.executeQuery();
    if(rs.next()) orders = rs.getInt(1);
    rs.close(); ps.close();

    // ── Recent Sessions ──
    ps = conn.prepareStatement("SELECT * FROM user_sessions ORDER BY started_at DESC LIMIT 10");
    rs = ps.executeQuery();
    List<Object[]> recentSessions = new ArrayList<>();

    while(rs.next()){
        String sid = rs.getString("session_id");
        if(sid == null) sid = "N/A";
        else if(sid.length()>8) sid = sid.substring(0,8)+"...";

        recentSessions.add(new Object[]{
            sid,
            rs.getString("user_email") == null ? "Guest" : rs.getString("user_email"),
            rs.getString("device_type"),
            rs.getString("ip_address"),
            0,
            rs.getTimestamp("started_at")
        });
    }
    rs.close(); ps.close();

    // ── Device Chart Data ──
    StringBuilder deviceLabels = new StringBuilder();
    StringBuilder deviceData = new StringBuilder();

    for(Map.Entry<String,Integer> e : deviceMap.entrySet()){
        if(deviceLabels.length()>0){
            deviceLabels.append(",");
            deviceData.append(",");
        }
        deviceLabels.append("'").append(e.getKey()).append("'");
        deviceData.append(e.getValue());
    }

    conn.close();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Analytics</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>

<body>

<h2>Analytics Dashboard</h2>

<!-- Funnel -->
<div>
    <h3>Conversion Funnel</h3>
    <p>Views: <%=views%></p>
    <p>Clicks: <%=clicks%></p>
    <p>Cart: <%=cart%></p>
    <p>Orders: <%=orders%></p>
</div>

<!-- Device Chart -->
<canvas id="deviceChart"></canvas>

<script>
var ctx = document.getElementById('deviceChart').getContext('2d');
new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: [<%= deviceLabels %>],
        datasets: [{
            data: [<%= deviceData %>]
        }]
    }
});
</script>

<!-- Recent Sessions -->
<table border="1">
<tr>
<th>ID</th><th>User</th><th>Device</th><th>IP</th><th>Time</th>
</tr>

<% for(Object[] s : recentSessions){ %>
<tr>
<td><%=s[0]%></td>
<td><%=s[1]%></td>
<td><%=s[2]%></td>
<td><%=s[3]%></td>
<td><%=s[5]%></td>
</tr>
<% } %>

</table>

</body>
</html>