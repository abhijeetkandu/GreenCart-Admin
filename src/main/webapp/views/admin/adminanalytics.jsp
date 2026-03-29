<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();
    PreparedStatement ps; ResultSet rs;

    // Total Sessions
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions");
    rs = ps.executeQuery();
    int totalSessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Today Sessions
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions WHERE DATE(started_at) = CURDATE()");
    rs = ps.executeQuery();
    int todaySessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Total Page Visits
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='page_visit'");
    rs = ps.executeQuery();
    int totalPageVisits = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Avg Time on Page (seconds)
    ps = conn.prepareStatement(
        "SELECT COALESCE(AVG(time_on_page), 0) FROM user_events " +
        "WHERE event_type IN ('time_on_page','time_spent') AND time_on_page > 0");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    // Total Add to Cart events
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='add_to_cart'");
    rs = ps.executeQuery();
    int totalCartAdds = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Total Orders
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders");
    rs = ps.executeQuery();
    int totalOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Pending Orders
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    int pendingOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Device Type Breakdown
    ps = conn.prepareStatement(
        "SELECT device_type, COUNT(*) as cnt FROM user_sessions " +
        "WHERE device_type IS NOT NULL GROUP BY device_type ORDER BY cnt DESC");
    rs = ps.executeQuery();
    Map<String,Integer> deviceMap = new LinkedHashMap<>();
    while (rs.next()) deviceMap.put(rs.getString("device_type"), rs.getInt("cnt"));
    rs.close(); ps.close();

    // Most Visited Pages
    ps = conn.prepareStatement(
        "SELECT page_url, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' AND page_url IS NOT NULL AND page_url != '' " +
        "GROUP BY page_url ORDER BY cnt DESC LIMIT 6");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while (rs.next()) topPages.add(new String[]{rs.getString("page_url"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Most Clicked Products
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='product_click' AND event_data IS NOT NULL AND event_data!='' " +
        "GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topProducts = new ArrayList<>();
    while (rs.next()) topProducts.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Most Added to Cart
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='add_to_cart' AND event_data IS NOT NULL AND event_data!='' " +
        "GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topCart = new ArrayList<>();
    while (rs.next()) topCart.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Page visits per day (last 7 days) for line chart
    ps = conn.prepareStatement(
        "SELECT DATE(created_at) as day, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
        "GROUP BY DATE(created_at) ORDER BY day ASC");
    rs = ps.executeQuery();
    List<String> chartDays  = new ArrayList<>();
    List<Integer> chartVals = new ArrayList<>();
    while (rs.next()) {
        chartDays.add(rs.getString("day"));
        chartVals.add(rs.getInt("cnt"));
    }
    rs.close(); ps.close();

    // Recent sessions
    ps = conn.prepareStatement(
        "SELECT session_id, user_email, device_type, ip_address, duration_seconds, started_at " +
        "FROM user_sessions ORDER BY started_at DESC LIMIT 8");
    rs = ps.executeQuery();
    List<Object[]> recentSessions = new ArrayList<>();
    while (rs.next()) {
        String sid = rs.getString("session_id");
        recentSessions.add(new Object[]{
            sid != null && sid.length() > 8 ? sid.substring(0, 8) + "…" : sid,
            rs.getString("user_email") != null ? rs.getString("user_email") : "Guest",
            rs.getString("device_type") != null ? rs.getString("device_type") : "Unknown",
            rs.getString("ip_address")  != null ? rs.getString("ip_address")  : "-",
            rs.getInt("duration_seconds"),
            rs.getTimestamp("started_at")
        });
    }
    rs.close(); ps.close();
    conn.close();

    // Build chart JSON
    StringBuilder deviceLabels = new StringBuilder();
    StringBuilder deviceData   = new StringBuilder();
    for (Map.Entry<String,Integer> e : deviceMap.entrySet()) {
        if (deviceLabels.length() > 0) { deviceLabels.append(","); deviceData.append(","); }
        deviceLabels.append("'").append(e.getKey()).append("'");
        deviceData.append(e.getValue());
    }
    StringBuilder lineLabels = new StringBuilder();
    StringBuilder lineData   = new StringBuilder();
    for (int i = 0; i < chartDays.size(); i++) {
        if (i > 0) { lineLabels.append(","); lineData.append(","); }
        lineLabels.append("'").append(chartDays.get(i)).append("'");
        lineData.append(chartVals.get(i));
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics – Green Cart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --forest:#0d2318; --sage:#2d8653; --mint:#4eca7f; --frost:#d4f5e4;
            --bg:#f2f4f3; --ember:#e8603c; --gold:#f0a843; --sky:#3a7bd5;
            --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        *{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Instrument Sans',sans-serif;background:var(--bg);color:var(--ink);min-height:100vh;display:flex;}

        /* SIDEBAR */
        .sidebar{width:230px;background:var(--forest);display:flex;flex-direction:column;position:fixed;top:0;bottom:0;left:0;z-index:200;}
        .sb-logo{padding:1.4rem 1.2rem 1rem;display:flex;align-items:center;gap:0.6rem;border-bottom:1px solid rgba(255,255,255,0.07);}
        .sb-mark{width:34px;height:34px;background:linear-gradient(135deg,var(--mint),var(--sage));border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:1rem;}
        .sb-txt{font-family:'Syne',sans-serif;font-weight:800;color:#fff;font-size:1rem;}
        .sb-txt span{color:var(--mint);}
        .sb-pill{background:rgba(78,202,127,0.15);color:var(--mint);font-size:0.58rem;font-weight:700;letter-spacing:1px;text-transform:uppercase;padding:0.12rem 0.45rem;border-radius:50px;margin-left:3px;}
        .sb-nav{flex:1;padding:0.8rem;overflow-y:auto;}
        .sb-lbl{font-size:0.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,0.28);padding:0.7rem 0.6rem 0.35rem;}
        .sb-item{display:flex;align-items:center;gap:0.7rem;padding:0.6rem 0.75rem;border-radius:9px;color:rgba(255,255,255,0.5);text-decoration:none;font-size:0.85rem;font-weight:500;transition:all 0.18s;margin-bottom:1px;}
        .sb-item:hover{background:rgba(255,255,255,0.07);color:rgba(255,255,255,0.9);}
        .sb-item.active{background:rgba(78,202,127,0.14);color:var(--mint);}
        .sb-badge{margin-left:auto;background:var(--ember);color:#fff;font-size:0.62rem;font-weight:700;padding:0.08rem 0.42rem;border-radius:50px;}
        .sb-foot{padding:0.9rem;border-top:1px solid rgba(255,255,255,0.07);}
        .sb-user{display:flex;align-items:center;gap:0.65rem;padding:0.65rem;border-radius:9px;background:rgba(255,255,255,0.05);margin-bottom:0.5rem;}
        .sb-av{width:30px;height:30px;background:linear-gradient(135deg,var(--mint),var(--sage));border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:0.85rem;}
        .sb-name{font-size:0.8rem;font-weight:600;color:#fff;}
        .sb-role{font-size:0.65rem;color:var(--mist);}
        .btn-logout{display:flex;align-items:center;justify-content:center;gap:0.4rem;width:100%;padding:0.5rem;background:rgba(232,96,60,0.1);color:var(--ember);border:1px solid rgba(232,96,60,0.2);border-radius:8px;font-size:0.8rem;font-weight:600;text-decoration:none;transition:all 0.2s;}
        .btn-logout:hover{background:var(--ember);color:#fff;}

        /* MAIN */
        .main{margin-left:230px;flex:1;min-height:100vh;}
        .topbar{background:var(--card);border-bottom:1px solid var(--border);padding:0.85rem 1.8rem;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;}
        .tb-title{font-family:'Syne',sans-serif;font-size:1.1rem;font-weight:700;}
        .btn-store{display:flex;align-items:center;gap:0.4rem;background:var(--frost);color:#1e5c38;border:1px solid rgba(30,92,56,0.15);border-radius:8px;padding:0.45rem 0.9rem;font-size:0.8rem;font-weight:600;text-decoration:none;transition:all 0.2s;}
        .btn-store:hover{background:#1e5c38;color:#fff;}
        .content{padding:1.6rem;}

        /* STATS */
        .stats{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;margin-bottom:1.4rem;}
        .sc{background:var(--card);border-radius:13px;padding:1.1rem 1.2rem;border:1px solid var(--border);display:flex;align-items:center;gap:0.9rem;}
        .si{font-size:1.4rem;width:44px;height:44px;border-radius:11px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
        .si.g{background:#e6f9ef;} .si.o{background:#fff0ec;} .si.b{background:#edf3ff;} .si.y{background:#fffbe6;} .si.p{background:#f3eeff;}
        .sv{font-family:'Syne',sans-serif;font-size:1.45rem;font-weight:800;color:var(--ink);line-height:1;}
        .sl{font-size:0.7rem;color:var(--mist);font-weight:500;margin-top:2px;}

        /* CARDS */
        .card{background:var(--card);border-radius:14px;border:1px solid var(--border);box-shadow:0 1px 4px rgba(0,0,0,0.04);overflow:hidden;margin-bottom:1.2rem;}
        .ch{padding:0.9rem 1.3rem;border-bottom:1px solid var(--border);}
        .ch-title{font-family:'Syne',sans-serif;font-size:0.88rem;font-weight:700;}
        .cb{padding:1.1rem 1.3rem;}

        /* GRIDS */
        .g2{display:grid;grid-template-columns:1fr 1fr;gap:1.2rem;margin-bottom:1.2rem;}
        .g3{display:grid;grid-template-columns:repeat(3,1fr);gap:1.2rem;margin-bottom:1.2rem;}

        /* BAR */
        .br{margin-bottom:0.8rem;}
        .bl{display:flex;justify-content:space-between;font-size:0.78rem;margin-bottom:3px;font-weight:500;}
        .bl span:last-child{color:var(--mist);}
        .bt{height:6px;background:#f0f0f0;border-radius:50px;overflow:hidden;}
        .bf{height:100%;border-radius:50px;background:linear-gradient(to right,var(--mint),var(--sage));}

        /* TABLE */
        .tbl{width:100%;border-collapse:collapse;}
        .tbl th{padding:0.7rem 1rem;font-size:0.68rem;font-weight:700;text-transform:uppercase;letter-spacing:0.7px;color:var(--mist);background:#f8faf9;text-align:left;border-bottom:1px solid var(--border);}
        .tbl td{padding:0.75rem 1rem;font-size:0.8rem;border-bottom:1px solid #f0f4f2;}
        .tbl tbody tr:last-child td{border-bottom:none;}
        .tbl tbody tr:hover{background:#fafffe;}
        .dm{border-radius:50px;padding:0.16rem 0.55rem;font-size:0.68rem;font-weight:700;}
        .dm-m{background:#e6f9ef;color:var(--sage);}
        .dm-d{background:#edf3ff;color:var(--sky);}
        .dm-t{background:#fffbe6;color:#b07d00;}
        .dm-u{background:#f5f5f5;color:var(--mist);}

        .empty{color:var(--mist);font-size:0.82rem;text-align:center;padding:2rem 0;}

        @media(max-width:900px){
            .sidebar{display:none;}
            .main{margin-left:0;}
            .stats{grid-template-columns:1fr 1fr;}
            .g2,.g3{grid-template-columns:1fr;}
        }
    </style>
</head>
<body>

<aside class="sidebar">
    <div class="sb-logo">
        <div class="sb-mark">🌿</div>
        <div class="sb-txt">Green<span>Cart</span><span class="sb-pill">Admin</span></div>
    </div>
    <nav class="sb-nav">
        <div class="sb-lbl">Overview</div>
        <a href="<%=request.getContextPath()%>/views/adminhome.jsp" class="sb-item"><span>🏠</span> Dashboard</a>
        <div class="sb-lbl">Catalog</div>
        <a href="<%=request.getContextPath()%>/views/adminhome.jsp" class="sb-item"><span>📦</span> Products</a>
        <div class="sb-lbl">Operations</div>
        <a href="<%=request.getContextPath()%>/views/adminorders.jsp" class="sb-item">
            <span>🧾</span> Orders
            <% if(pendingOrders > 0){%><span class="sb-badge"><%= pendingOrders %></span><%}%>
        </a>
        <a href="<%=request.getContextPath()%>/views/adminusers.jsp" class="sb-item"><span>👥</span> Customers</a>
        <a href="<%=request.getContextPath()%>/views/adminanalytics.jsp" class="sb-item active"><span>📈</span> Analytics</a>
    </nav>
    <div class="sb-foot">
        <div class="sb-user">
            <div class="sb-av">👤</div>
            <div><div class="sb-name"><%= admin %></div><div class="sb-role">Super Admin</div></div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">🚪 Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div class="tb-title">📈 Analytics Dashboard</div>
        <a href="<%=request.getContextPath()%>/views/home.jsp" class="btn-store" target="_blank">🌐 View Store</a>
    </div>
    <div class="content">

        <%-- STAT CARDS --%>
        <div class="stats">
            <div class="sc"><div class="si g">👁️</div><div><div class="sv"><%= todaySessions %></div><div class="sl">Sessions Today</div></div></div>
            <div class="sc"><div class="si b">🌐</div><div><div class="sv"><%= totalSessions %></div><div class="sl">Total Sessions</div></div></div>
            <div class="sc"><div class="si o">📄</div><div><div class="sv"><%= totalPageVisits %></div><div class="sl">Page Visits</div></div></div>
            <div class="sc"><div class="si y">⏱️</div><div><div class="sv"><%= String.format("%.0f",avgTime) %>s</div><div class="sl">Avg Time on Page</div></div></div>
        </div>
        <div class="stats">
            <div class="sc"><div class="si p">🛒</div><div><div class="sv"><%= totalCartAdds %></div><div class="sl">Add to Cart Events</div></div></div>
            <div class="sc"><div class="si g">📦</div><div><div class="sv"><%= totalOrders %></div><div class="sl">Total Orders</div></div></div>
            <div class="sc"><div class="si o">⏳</div><div><div class="sv"><%= pendingOrders %></div><div class="sl">Pending Orders</div></div></div>
            <div class="sc"><div class="si b">📊</div><div><div class="sv"><%= totalPageVisits > 0 ? String.format("%.1f",(totalOrders*100.0/totalPageVisits)) : "0.0" %>%</div><div class="sl">Conversion Rate</div></div></div>
        </div>

        <%-- LINE CHART: Page Visits Last 7 Days --%>
        <div class="card">
            <div class="ch"><div class="ch-title">📅 Page Visits — Last 7 Days</div></div>
            <div class="cb">
                <% if (chartDays.isEmpty()) { %>
                    <p class="empty">No visit data yet — add tracking.js to your user pages</p>
                <% } else { %>
                    <canvas id="lineChart" height="80"></canvas>
                <% } %>
            </div>
        </div>

        <%-- ROW: Device + Top Pages + Top Products --%>
        <div class="g3">
            <div class="card">
                <div class="ch"><div class="ch-title">📱 Device Types</div></div>
                <div class="cb" style="display:flex;align-items:center;justify-content:center;min-height:180px;">
                    <% if (deviceMap.isEmpty()) { %>
                        <p class="empty">No session data yet</p>
                    <% } else { %>
                        <canvas id="deviceChart" width="180" height="180"></canvas>
                    <% } %>
                </div>
            </div>
            <div class="card">
                <div class="ch"><div class="ch-title">📄 Top Pages Visited</div></div>
                <div class="cb">
                    <% if (topPages.isEmpty()) { %>
                        <p class="empty">No data yet</p>
                    <% } else {
                        int mx = Integer.parseInt(topPages.get(0)[1]);
                        for (String[] pg : topPages) {
                            int c = Integer.parseInt(pg[1]);
                            int p = mx > 0 ? c*100/mx : 0;
                    %>
                    <div class="br">
                        <div class="bl"><span><%= pg[0] %></span><span><%= c %></span></div>
                        <div class="bt"><div class="bf" style="width:<%= p %>%"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
            <div class="card">
                <div class="ch"><div class="ch-title">🔥 Most Clicked Products</div></div>
                <div class="cb">
                    <% if (topProducts.isEmpty()) { %>
                        <p class="empty">No product clicks yet</p>
                    <% } else {
                        int mx = Integer.parseInt(topProducts.get(0)[1]);
                        for (String[] pr : topProducts) {
                            int c = Integer.parseInt(pr[1]);
                            int p = mx > 0 ? c*100/mx : 0;
                    %>
                    <div class="br">
                        <div class="bl"><span><%= pr[0] %></span><span><%= c %></span></div>
                        <div class="bt"><div class="bf" style="width:<%= p %>%;background:linear-gradient(to right,#f0a843,var(--ember))"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
        </div>

        <%-- ROW: Cart Adds + Orders --%>
        <div class="g2">
            <div class="card">
                <div class="ch"><div class="ch-title">🛒 Most Added to Cart</div></div>
                <div class="cb">
                    <% if (topCart.isEmpty()) { %>
                        <p class="empty">No cart events yet</p>
                    <% } else {
                        int mx = Integer.parseInt(topCart.get(0)[1]);
                        for (String[] ci : topCart) {
                            int c = Integer.parseInt(ci[1]);
                            int p = mx > 0 ? c*100/mx : 0;
                    %>
                    <div class="br">
                        <div class="bl"><span><%= ci[0] %></span><span><%= c %> times</span></div>
                        <div class="bt"><div class="bf" style="width:<%= p %>%;background:linear-gradient(to right,var(--mint),#0d2318)"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
            <div class="card">
                <div class="ch"><div class="ch-title">📦 Order Summary</div></div>
                <div class="cb" style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:140px;gap:0.6rem;">
                    <div style="font-family:'Syne',sans-serif;font-size:2.8rem;font-weight:800;color:var(--ink)"><%= totalOrders %></div>
                    <div style="color:var(--mist);font-size:0.82rem;">Total Orders Placed</div>
                    <div style="background:var(--frost);border-radius:8px;padding:0.4rem 1.2rem;font-size:0.8rem;color:#1e5c38;font-weight:600;">
                        <%= pendingOrders %> Pending &nbsp;|&nbsp;
                        <%= totalOrders - pendingOrders %> Completed
                    </div>
                </div>
            </div>
        </div>

        <%-- RECENT SESSIONS --%>
        <div class="card">
            <div class="ch"><div class="ch-title">🕐 Recent Sessions</div></div>
            <div style="overflow-x:auto;">
                <table class="tbl">
                    <thead>
                        <tr>
                            <th>Session</th>
                            <th>User</th>
                            <th>Device</th>
                            <th>IP</th>
                            <th>Duration</th>
                            <th>Started</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% if (recentSessions.isEmpty()) { %>
                        <tr><td colspan="6" class="empty">No sessions yet — make sure tracking.js is added to user pages</td></tr>
                    <% } else {
                        for (Object[] s : recentSessions) {
                            String dev = (String)s[2];
                            String dc = "dm dm-u";
                            if("Mobile".equals(dev))  dc="dm dm-m";
                            if("Desktop".equals(dev)) dc="dm dm-d";
                            if("Tablet".equals(dev))  dc="dm dm-t";
                            int dur = (Integer)s[4];
                    %>
                    <tr>
                        <td style="font-family:monospace;font-size:0.72rem;color:var(--mist)"><%= s[0] %></td>
                        <td style="font-weight:500"><%= s[1] %></td>
                        <td><span class="<%= dc %>"><%= dev %></span></td>
                        <td style="font-size:0.75rem;color:var(--mist)"><%= s[3] %></td>
                        <td><%= dur > 0 ? dur+"s" : "—" %></td>
                        <td style="font-size:0.75rem;color:var(--mist)"><%= s[5] %></td>
                    </tr>
                    <% } } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</div>

<script>
// Line Chart — Page Visits Last 7 Days
<% if (!chartDays.isEmpty()) { %>
new Chart(document.getElementById('lineChart'), {
    type: 'line',
    data: {
        labels: [<%= lineLabels %>],
        datasets: [{
            label: 'Page Visits',
            data:  [<%= lineData %>],
            borderColor: '#4eca7f',
            backgroundColor: 'rgba(78,202,127,0.1)',
            borderWidth: 2.5,
            pointBackgroundColor: '#4eca7f',
            pointRadius: 4,
            tension: 0.4,
            fill: true
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
            y: { beginAtZero: true, grid: { color: '#f0f0f0' }, ticks: { font: { family: 'Instrument Sans' } } },
            x: { grid: { display: false }, ticks: { font: { family: 'Instrument Sans' } } }
        }
    }
});
<% } %>

// Doughnut Chart — Device Types
<% if (!deviceMap.isEmpty()) { %>
new Chart(document.getElementById('deviceChart'), {
    type: 'doughnut',
    data: {
        labels: [<%= deviceLabels %>],
        datasets: [{
            data: [<%= deviceData %>],
            backgroundColor: ['#4eca7f','#3a7bd5','#f0a843'],
            borderWidth: 0,
            hoverOffset: 6
        }]
    },
    options: {
        responsive: false,
        plugins: {
            legend: { position:'bottom', labels:{ font:{ family:'Instrument Sans', size:11 }, padding:10 } }
        },
        cutout: '62%'
    }
});
<% } %>
</script>
</body>
</html>
