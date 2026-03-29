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

    int todaySessions=0,totalSessions=0,totalEvents=0,totalOrders=0,pendingOrders=0;
    double avgTime=0;

    // Sessions Today
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions WHERE DATE(started_at)=CURDATE()");
    rs = ps.executeQuery();
    if(rs.next()) todaySessions = rs.getInt(1);
    rs.close(); ps.close();

    // Total Sessions
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions");
    rs = ps.executeQuery();
    if(rs.next()) totalSessions = rs.getInt(1);
    rs.close(); ps.close();

    // Total Events
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events");
    rs = ps.executeQuery();
    if(rs.next()) totalEvents = rs.getInt(1);
    rs.close(); ps.close();

    // Orders
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='order_completed'");
    rs = ps.executeQuery();
    if(rs.next()) totalOrders = rs.getInt(1);
    rs.close(); ps.close();

    // Pending Orders
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    if(rs.next()) pendingOrders = rs.getInt(1);
    rs.close(); ps.close();

    // Device Map
    Map<String,Integer> deviceMap = new LinkedHashMap<>();
    ps = conn.prepareStatement("SELECT IFNULL(device_type,'Unknown'), COUNT(*) FROM user_sessions GROUP BY device_type");
    rs = ps.executeQuery();
    while(rs.next()){
        deviceMap.put(rs.getString(1), rs.getInt(2));
    }
    rs.close(); ps.close();

    // Funnel
    int views=0,clicks=0,cart=0,orders=0;

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

    // Recent Sessions
    List<Object[]> recentSessions = new ArrayList<>();
    ps = conn.prepareStatement("SELECT * FROM user_sessions ORDER BY started_at DESC LIMIT 10");
    rs = ps.executeQuery();

    while(rs.next()){
        recentSessions.add(new Object[]{
            rs.getString("session_id"),
            rs.getString("user_email"),
            rs.getString("device_type"),
            rs.getString("ip_address"),
            rs.getTimestamp("started_at")
        });
    }
    rs.close(); ps.close();

    // Chart Data
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
<html>
<head>
<title>Analytics Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>

<body style="background:#f2f4f3;font-family:sans-serif;">

<div class="container mt-4">

<h2>📊 Analytics Dashboard</h2>

<!-- Stats -->
<div class="row mt-3">
<div class="col-md-3"><div class="card p-3">Sessions Today<br><b><%=todaySessions%></b></div></div>
<div class="col-md-3"><div class="card p-3">Total Sessions<br><b><%=totalSessions%></b></div></div>
<div class="col-md-3"><div class="card p-3">Events<br><b><%=totalEvents%></b></div></div>
<div class="col-md-3"><div class="card p-3">Avg Time<br><b><%=avgTime%></b></div></div>
</div>

<!-- Funnel -->
<div class="card mt-4 p-3">
<h4>🔥 Conversion Funnel</h4>
<p>Views: <%=views%></p>
<p>Clicks: <%=clicks%></p>
<p>Cart: <%=cart%></p>
<p>Orders: <%=orders%></p>
</div>

<!-- Chart -->
<div class="card mt-4 p-3">
<h4>📱 Device Distribution</h4>
<canvas id="chart"></canvas>
</div>

<!-- Table -->
<div class="card mt-4 p-3">
<h4>🕐 Recent Sessions</h4>
<table class="table">
<tr><th>ID</th><th>User</th><th>Device</th><th>IP</th><th>Time</th></tr>
<% for(Object[] s : recentSessions){ %>
<tr>
<td><%=s[0]%></td>
<td><%=s[1]%></td>
<td><%=s[2]%></td>
<td><%=s[3]%></td>
<td><%=s[4]%></td>
</tr>
<% } %>
</table>
</div>

</div>

<script>
new Chart(document.getElementById('chart'), {
    type:'doughnut',
    data:{
        labels:[<%=deviceLabels%>],
        datasets:[{data:[<%=deviceData%>]}]
    }
});
</script>

</body>
</html>