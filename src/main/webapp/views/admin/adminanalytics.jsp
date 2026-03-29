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

    // Total Sessions Today
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions WHERE DATE(started_at) = CURDATE()");
    rs = ps.executeQuery();
    int todaySessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Total Sessions All Time
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions");
    rs = ps.executeQuery();
    int totalSessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Total Events
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events");
    rs = ps.executeQuery();
    int totalEvents = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Orders Placed (from user_events)
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events WHERE event_type='order_placed'");
    rs = ps.executeQuery();
    int totalOrderEvents = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Pending orders badge
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    int pendingOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Avg Time on Page
    ps = conn.prepareStatement(
        "SELECT AVG(time_on_page) FROM user_events WHERE event_type='time_on_page' AND time_on_page > 0");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    // Device Type Breakdown
    ps = conn.prepareStatement(
        "SELECT device_type, COUNT(*) as cnt FROM user_sessions WHERE device_type IS NOT NULL GROUP BY device_type ORDER BY cnt DESC");
    rs = ps.executeQuery();
    Map<String, Integer> deviceMap = new LinkedHashMap<>();
    while (rs.next()) deviceMap.put(rs.getString("device_type"), rs.getInt("cnt"));
    rs.close(); ps.close();

    // Most Visited Pages
    ps = conn.prepareStatement(
        "SELECT page_url, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' AND page_url IS NOT NULL AND page_url != '' " +
        "GROUP BY page_url ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while (rs.next()) topPages.add(new String[]{rs.getString("page_url"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Most Clicked Products
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='product_click' AND event_data IS NOT NULL AND event_data != '' " +
        "GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topProducts = new ArrayList<>();
    while (rs.next()) topProducts.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Most Added to Cart
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='add_to_cart' AND event_data IS NOT NULL AND event_data != '' " +
        "GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topCart = new ArrayList<>();
    while (rs.next()) topCart.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // Recent Sessions
    ps = conn.prepareStatement(
        "SELECT * FROM user_sessions ORDER BY started_at DESC LIMIT 10");
    rs = ps.executeQuery();
    List<Object[]> recentSessions = new ArrayList<>();
    while (rs.next()) {
        String sid = rs.getString("session_id");
        recentSessions.add(new Object[]{
            sid != null && sid.length() > 8 ? sid.substring(0, 8) + "..." : sid,
            rs.getString("user_email") != null ? rs.getString("user_email") : "Guest",
            rs.getString("device_type") != null ? rs.getString("device_type") : "Unknown",
            rs.getString("ip_address") != null ? rs.getString("ip_address") : "-",
            rs.getInt("duration_seconds"),
            rs.getTimestamp("started_at")
        });
    }
    rs.close(); ps.close();
    conn.close();

    // Build chart data
    StringBuilder deviceLabels = new StringBuilder();
    StringBuilder deviceData   = new StringBuilder();
    for (Map.Entry<String, Integer> e : deviceMap.entrySet()) {
        if (deviceLabels.length() > 0) { deviceLabels.append(","); deviceData.append(","); }
        deviceLabels.append("'").append(e.getKey()).append("'");
        deviceData.append(e.getValue());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics – Green Cart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --forest:#0d2318; --pine:#153a25; --leaf:#1e5c38; --sage:#2d8653; --mint:#4eca7f;
            --frost:#d4f5e4; --cream:#f7f3ed; --bg:#f2f4f3; --ember:#e8603c; --gold:#f0a843;
            --sky:#3a7bd5; --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Instrument Sans',sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; }

        /* SIDEBAR */
        .sidebar { position:fixed; left:0; top:0; bottom:0; width:240px; background:var(--forest); display:flex; flex-direction:column; z-index:200; }
        .sidebar-logo { padding:1.5rem 1.5rem 1rem; display:flex; align-items:center; gap:0.7rem; border-bottom:1px solid rgba(255,255,255,0.07); }
        .logo-mark { width:36px; height:36px; background:linear-gradient(135deg,var(--mint),var(--sage)); border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:1.1rem; }
        .logo-txt { font-family:'Syne',sans-serif; font-weight:800; color:#fff; font-size:1.1rem; }
        .logo-txt span { color:var(--mint); }
        .admin-pill { background:rgba(78,202,127,0.15); color:var(--mint); font-size:0.6rem; font-weight:700; letter-spacing:1.2px; text-transform:uppercase; padding:0.15rem 0.5rem; border-radius:50px; margin-left:4px; }
        .sidebar-nav { flex:1; padding:1rem 0.8rem; overflow-y:auto; }
        .nav-section-label { font-size:0.65rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:rgba(255,255,255,0.3); padding:0.8rem 0.7rem 0.4rem; }
        .nav-item { display:flex; align-items:center; gap:0.75rem; padding:0.65rem 0.8rem; border-radius:10px; color:rgba(255,255,255,0.55); text-decoration:none; font-size:0.88rem; font-weight:500; transition:all 0.2s; margin-bottom:2px; }
        .nav-item:hover { background:rgba(255,255,255,0.07); color:rgba(255,255,255,0.9); }
        .nav-item.active { background:rgba(78,202,127,0.15); color:var(--mint); }
        .nav-badge { margin-left:auto; background:var(--ember); color:#fff; font-size:0.65rem; font-weight:700; padding:0.1rem 0.45rem; border-radius:50px; }
        .sidebar-footer { padding:1rem; border-top:1px solid rgba(255,255,255,0.07); }
        .admin-info { display:flex; align-items:center; gap:0.7rem; padding:0.7rem; border-radius:10px; background:rgba(255,255,255,0.06); margin-bottom:0.5rem; }
        .admin-avatar { width:32px; height:32px; background:linear-gradient(135deg,var(--mint),var(--sage)); border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:0.9rem; }
        .admin-name { font-size:0.82rem; font-weight:600; color:#fff; }
        .admin-role { font-size:0.68rem; color:var(--mist); }
        .btn-logout { display:flex; align-items:center; justify-content:center; gap:0.5rem; width:100%; padding:0.55rem; background:rgba(232,96,60,0.1); color:var(--ember); border:1px solid rgba(232,96,60,0.2); border-radius:8px; font-size:0.82rem; font-weight:600; text-decoration:none; transition:all 0.2s; }
        .btn-logout:hover { background:var(--ember); color:#fff; }

        .sidebar-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.5); z-index:199; }

        .main { margin-left:240px; min-height:100vh; }
        .topbar { background:var(--card); border-bottom:1px solid var(--border); padding:0.9rem 2rem; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:100; }
        .topbar-title { font-family:'Syne',sans-serif; font-size:1.15rem; font-weight:700; color:var(--ink); }
        .btn-hamburger { display:none; background:none; border:none; font-size:1.4rem; cursor:pointer; }
        .btn-view-store { display:flex; align-items:center; gap:0.5rem; background:var(--frost); color:var(--leaf); border:1px solid rgba(30,92,56,0.15); border-radius:8px; padding:0.5rem 1rem; font-size:0.82rem; font-weight:600; text-decoration:none; transition:all 0.2s; }
        .btn-view-store:hover { background:var(--leaf); color:#fff; }
        .page-content { padding:2rem; }

        /* STAT CARDS */
        .stats-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:1rem; margin-bottom:1.5rem; }
        .stat-card { background:var(--card); border-radius:14px; padding:1.2rem 1.3rem; border:1px solid var(--border); display:flex; align-items:center; gap:1rem; }
        .stat-icon { font-size:1.5rem; width:46px; height:46px; border-radius:12px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .stat-icon.green  { background:#e6f9ef; }
        .stat-icon.orange { background:#fff0ec; }
        .stat-icon.blue   { background:#edf3ff; }
        .stat-icon.yellow { background:#fffbe6; }
        .stat-value { font-family:'Syne',sans-serif; font-size:1.5rem; font-weight:800; color:var(--ink); line-height:1; }
        .stat-label { font-size:0.72rem; color:var(--mist); font-weight:500; margin-top:2px; }

        /* SECTION CARD */
        .section-card { background:var(--card); border-radius:16px; border:1px solid var(--border); box-shadow:0 1px 6px rgba(0,0,0,0.04); overflow:hidden; margin-bottom:1.5rem; }
        .section-head { padding:1rem 1.4rem; border-bottom:1px solid var(--border); }
        .section-head-title { font-family:'Syne',sans-serif; font-size:0.92rem; font-weight:700; color:var(--ink); }
        .section-body { padding:1.2rem 1.4rem; }

        /* BAR ROW */
        .bar-row { margin-bottom:0.85rem; }
        .bar-label { display:flex; justify-content:space-between; font-size:0.8rem; color:var(--ink); margin-bottom:4px; font-weight:500; }
        .bar-label span:last-child { color:var(--mist); }
        .bar-track { height:7px; background:#f0f0f0; border-radius:50px; overflow:hidden; }
        .bar-fill { height:100%; border-radius:50px; background:linear-gradient(to right,var(--mint),var(--sage)); transition:width 1s ease; }

        /* TABLE */
        .sessions-table { width:100%; border-collapse:collapse; }
        .sessions-table th { padding:0.75rem 1rem; font-size:0.7rem; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; color:var(--mist); background:#f8faf9; text-align:left; border-bottom:1px solid var(--border); }
        .sessions-table td { padding:0.8rem 1rem; font-size:0.82rem; color:var(--ink); border-bottom:1px solid #f0f4f2; }
        .sessions-table tbody tr:hover { background:#fafffe; }
        .sessions-table tbody tr:last-child td { border-bottom:none; }
        .device-mobile  { background:#e6f9ef; color:var(--sage); border-radius:50px; padding:0.18rem 0.6rem; font-size:0.7rem; font-weight:700; }
        .device-desktop { background:#edf3ff; color:var(--sky); border-radius:50px; padding:0.18rem 0.6rem; font-size:0.7rem; font-weight:700; }
        .device-tablet  { background:#fffbe6; color:#b07d00; border-radius:50px; padding:0.18rem 0.6rem; font-size:0.7rem; font-weight:700; }

        .grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:1.5rem; margin-bottom:1.5rem; }
        .grid-3 { display:grid; grid-template-columns:repeat(3,1fr); gap:1.5rem; margin-bottom:1.5rem; }

        .empty-msg { color:var(--mist); font-size:0.85rem; text-align:center; padding:1.5rem 0; }

        @keyframes fadeUp { from{opacity:0;transform:translateY(12px)} to{opacity:1;transform:translateY(0)} }
        .fade-up { animation:fadeUp 0.3s ease forwards; }

        @media(max-width:768px) {
            .sidebar { transform:translateX(-100%); transition:transform 0.3s; }
            .sidebar.open { transform:translateX(0); }
            .sidebar-overlay.open { display:block; }
            .main { margin-left:0; }
            .btn-hamburger { display:block; }
            .stats-grid { grid-template-columns:1fr 1fr; }
            .grid-2, .grid-3 { grid-template-columns:1fr; }
            .page-content { padding:1rem; }
        }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<aside class="sidebar" id="sidebar">
    <div class="sidebar-logo">
        <div class="logo-mark">🌿</div>
        <div class="logo-txt">Green<span>Cart</span> <span class="admin-pill">Admin</span></div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Overview</div>
        <a href="<%=request.getContextPath()%>/views/adminhome.jsp" class="nav-item"><span>📊</span> Dashboard</a>
        <div class="nav-section-label">Catalog</div>
        <a href="<%=request.getContextPath()%>/views/adminhome.jsp" class="nav-item"><span>📦</span> Products</a>
        <div class="nav-section-label">Operations</div>
        <a href="<%=request.getContextPath()%>/views/adminorders.jsp" class="nav-item">
            <span>🧾</span> Orders
            <% if(pendingOrders > 0) { %><span class="nav-badge"><%= pendingOrders %></span><% } %>
        </a>
        <a href="<%=request.getContextPath()%>/views/adminusers.jsp" class="nav-item"><span>👥</span> Customers</a>
        <a href="<%=request.getContextPath()%>/views/adminanalytics.jsp" class="nav-item active"><span>📈</span> Analytics</a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-info">
            <div class="admin-avatar">👤</div>
            <div>
                <div class="admin-name"><%= admin %></div>
                <div class="admin-role">Super Admin</div>
            </div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">🚪 Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div style="display:flex;align-items:center;gap:0.75rem;">
            <button class="btn-hamburger" onclick="openSidebar()">☰</button>
            <div class="topbar-title">📈 Analytics Dashboard</div>
        </div>
        <a href="<%=request.getContextPath()%>/views/home.jsp" class="btn-view-store" target="_blank">🌐 View Store</a>
    </div>

    <div class="page-content">

        <%-- STAT CARDS --%>
        <div class="stats-grid fade-up">
            <div class="stat-card">
                <div class="stat-icon green">👁️</div>
                <div><div class="stat-value"><%= todaySessions %></div><div class="stat-label">Sessions Today</div></div>
            </div>
            <div class="stat-card">
                <div class="stat-icon blue">🌐</div>
                <div><div class="stat-value"><%= totalSessions %></div><div class="stat-label">Total Sessions</div></div>
            </div>
            <div class="stat-card">
                <div class="stat-icon orange">⚡</div>
                <div><div class="stat-value"><%= totalEvents %></div><div class="stat-label">Total Events</div></div>
            </div>
            <div class="stat-card">
                <div class="stat-icon yellow">⏱️</div>
                <div><div class="stat-value"><%= String.format("%.0f", avgTime) %>s</div><div class="stat-label">Avg Time on Page</div></div>
            </div>
        </div>

        <%-- ROW 1: Device + Top Pages + Top Products --%>
        <div class="grid-3">
            <%-- Device Chart --%>
            <div class="section-card fade-up">
                <div class="section-head"><div class="section-head-title">📱 Device Types</div></div>
                <div class="section-body" style="display:flex;align-items:center;justify-content:center;min-height:200px;">
                    <% if (deviceMap.isEmpty()) { %>
                        <p class="empty-msg">No data yet.<br>Visit the user website to start tracking!</p>
                    <% } else { %>
                        <canvas id="deviceChart" width="200" height="200"></canvas>
                    <% } %>
                </div>
            </div>

            <%-- Top Pages --%>
            <div class="section-card fade-up">
                <div class="section-head"><div class="section-head-title">📄 Most Visited Pages</div></div>
                <div class="section-body">
                    <% if (topPages.isEmpty()) { %>
                        <p class="empty-msg">No page visits tracked yet</p>
                    <% } else {
                        int maxPage = Integer.parseInt(topPages.get(0)[1]);
                        for (String[] pageItem : topPages) {
                            int cnt = Integer.parseInt(pageItem[1]);
                            int pct = maxPage > 0 ? (cnt * 100 / maxPage) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label"><span><%= pageItem[0] %></span><span><%= cnt %></span></div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>

            <%-- Top Products --%>
            <div class="section-card fade-up">
                <div class="section-head"><div class="section-head-title">🔥 Most Clicked Products</div></div>
                <div class="section-body">
                    <% if (topProducts.isEmpty()) { %>
                        <p class="empty-msg">No product clicks tracked yet</p>
                    <% } else {
                        int maxProd = Integer.parseInt(topProducts.get(0)[1]);
                        for (String[] prod : topProducts) {
                            int cnt = Integer.parseInt(prod[1]);
                            int pct = maxProd > 0 ? (cnt * 100 / maxProd) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label"><span><%= prod[0] %></span><span><%= cnt %></span></div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%;background:linear-gradient(to right,#f0a843,var(--ember))"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
        </div>

        <%-- ROW 2: Cart + Orders --%>
        <div class="grid-2">
            <%-- Top Cart --%>
            <div class="section-card fade-up">
                <div class="section-head"><div class="section-head-title">🛒 Most Added to Cart</div></div>
                <div class="section-body">
                    <% if (topCart.isEmpty()) { %>
                        <p class="empty-msg">No cart events tracked yet</p>
                    <% } else {
                        int maxCart = Integer.parseInt(topCart.get(0)[1]);
                        for (String[] cartItem : topCart) {
                            int cnt = Integer.parseInt(cartItem[1]);
                            int pct = maxCart > 0 ? (cnt * 100 / maxCart) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label"><span><%= cartItem[0] %></span><span><%= cnt %> times</span></div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%;background:linear-gradient(to right,var(--mint),var(--forest))"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>

            <%-- Order Completion --%>
            <div class="section-card fade-up">
                <div class="section-head"><div class="section-head-title">📦 Order Completion</div></div>
                <div class="section-body" style="display:flex;align-items:center;justify-content:center;flex-direction:column;min-height:150px;gap:0.5rem;">
                    <div style="font-family:'Syne',sans-serif;font-size:3rem;font-weight:800;color:var(--ink)"><%= totalOrderEvents %></div>
                    <div style="color:var(--mist);font-size:0.85rem;">Orders Placed via Website</div>
                    <div style="background:var(--frost);border-radius:10px;padding:0.5rem 1.4rem;font-size:0.82rem;color:var(--leaf);font-weight:600;margin-top:0.5rem;">
                        <%= totalSessions > 0 ? String.format("%.1f", (totalOrderEvents * 100.0 / totalSessions)) : "0.0" %>% Conversion Rate
                    </div>
                </div>
            </div>
        </div>

        <%-- RECENT SESSIONS --%>
        <div class="section-card fade-up">
            <div class="section-head"><div class="section-head-title">🕐 Recent Sessions</div></div>
            <div style="overflow-x:auto;">
                <table class="sessions-table">
                    <thead>
                        <tr>
                            <th>Session ID</th>
                            <th>User</th>
                            <th>Device</th>
                            <th>IP Address</th>
                            <th>Duration</th>
                            <th>Started At</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% if (recentSessions.isEmpty()) { %>
                        <tr><td colspan="6" class="empty-msg">No sessions recorded yet. Add the tracking script to your user pages!</td></tr>
                    <% } else {
                        for (Object[] s : recentSessions) {
                            String device = (String) s[2];
                            String deviceClass = "device-desktop";
                            if ("Mobile".equals(device)) deviceClass = "device-mobile";
                            if ("Tablet".equals(device)) deviceClass = "device-tablet";
                            int dur = (Integer) s[4];
                    %>
                    <tr>
                        <td style="font-size:0.72rem;color:var(--mist);font-family:monospace"><%= s[0] %></td>
                        <td style="font-weight:500"><%= s[1] %></td>
                        <td><span class="<%= deviceClass %>"><%= device %></span></td>
                        <td style="font-size:0.78rem;color:var(--mist)"><%= s[3] %></td>
                        <td><%= dur > 0 ? dur + "s" : "-" %></td>
                        <td style="font-size:0.78rem;color:var(--mist)"><%= s[5] %></td>
                    </tr>
                    <% } } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</div>

<script>
    function openSidebar()  { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebarOverlay').classList.add('open'); }
    function closeSidebar() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebarOverlay').classList.remove('open'); }

    <% if (!deviceMap.isEmpty()) { %>
    var ctx = document.getElementById('deviceChart').getContext('2d');
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [<%= deviceLabels %>],
            datasets: [{
                data: [<%= deviceData %>],
                backgroundColor: ['#4eca7f', '#3a7bd5', '#f0a843'],
                borderWidth: 0,
                hoverOffset: 8
            }]
        },
        options: {
            responsive: false,
            plugins: {
                legend: { position:'bottom', labels:{ font:{ family:'Instrument Sans', size:12 }, padding:12 } }
            },
            cutout: '65%'
        }
    });
    <% } %>
</script>
</body>
</html>
