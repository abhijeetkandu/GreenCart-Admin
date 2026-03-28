<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();

    // ── Total Sessions Today ───────────────────────────────────────
    PreparedStatement ps = conn.prepareStatement(
        "SELECT COUNT(*) FROM user_sessions WHERE DATE(started_at) = CURDATE()");
    ResultSet rs = ps.executeQuery();
    int todaySessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Total Sessions All Time ────────────────────────────────────
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_sessions");
    rs = ps.executeQuery();
    int totalSessions = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Total Events ───────────────────────────────────────────────
    ps = conn.prepareStatement("SELECT COUNT(*) FROM user_events");
    rs = ps.executeQuery();
    int totalEvents = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Orders Placed ──────────────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT COUNT(*) FROM user_events WHERE event_type='order_placed'");
    rs = ps.executeQuery();
    int totalOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // ── Device Type Breakdown ──────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT device_type, COUNT(*) as cnt FROM user_sessions GROUP BY device_type");
    rs = ps.executeQuery();
    Map<String, Integer> deviceMap = new LinkedHashMap<>();
    while (rs.next()) deviceMap.put(rs.getString("device_type"), rs.getInt("cnt"));
    rs.close(); ps.close();

    // ── Most Visited Pages ─────────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT page_url, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' GROUP BY page_url ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while (rs.next()) topPages.add(new String[]{rs.getString("page_url"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // ── Most Clicked Products ──────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='product_click' GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topProducts = new ArrayList<>();
    while (rs.next()) topProducts.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // ── Most Added to Cart ─────────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT event_data, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='add_to_cart' GROUP BY event_data ORDER BY cnt DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> topCart = new ArrayList<>();
    while (rs.next()) topCart.add(new String[]{rs.getString("event_data"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    // ── Avg Time on Page ──────────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT AVG(time_on_page) FROM user_events WHERE event_type='time_on_page' AND time_on_page > 0");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    // ── Recent Sessions ────────────────────────────────────────────
    ps = conn.prepareStatement(
        "SELECT * FROM user_sessions ORDER BY started_at DESC LIMIT 10");
    rs = ps.executeQuery();
    List<Object[]> recentSessions = new ArrayList<>();
    while (rs.next()) {
        recentSessions.add(new Object[]{
            rs.getString("session_id").substring(0, 8) + "...",
            rs.getString("user_email"),
            rs.getString("device_type"),
            rs.getString("ip_address"),
            rs.getInt("duration_seconds"),
            rs.getTimestamp("started_at")
        });
    }
    rs.close(); ps.close();
    conn.close();

    // Build device chart data
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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --green-dark:#1a3c2b; --green-mid:#2d6a4f; --green-light:#52b788;
            --cream:#f5f0e8; --warm-white:#fdfaf5; --accent:#e76f51;
            --text-dark:#1a1a1a; --text-muted:#7a7a6a;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'DM Sans',sans-serif; background:#f0f2f0; min-height:100vh; }

        .navbar-custom { background:var(--green-dark); padding:0.85rem 0; position:sticky; top:0; z-index:100; box-shadow:0 2px 20px rgba(0,0,0,0.3); }
        .brand-text { font-family:'Playfair Display',serif; font-size:1.5rem; font-weight:900; color:#fff; }
        .brand-dot  { color:var(--green-light); }
        .admin-tag  { background:rgba(255,255,255,0.12); color:rgba(255,255,255,0.8); font-size:0.72rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; padding:0.2rem 0.7rem; border-radius:50px; margin-left:0.6rem; }
        .btn-nav    { color:rgba(255,255,255,0.75); text-decoration:none; border:1px solid rgba(255,255,255,0.25); border-radius:50px; padding:0.35rem 1rem; font-size:0.83rem; transition:all 0.2s; margin-left:0.5rem; }
        .btn-nav:hover { color:#fff; background:rgba(255,255,255,0.1); }

        .page-header { background:linear-gradient(135deg,var(--green-dark),var(--green-mid)); padding:2rem 0 1.5rem; color:#fff; }
        .page-header h1 { font-family:'Playfair Display',serif; font-size:1.8rem; font-weight:900; }
        .page-header p  { color:rgba(255,255,255,0.65); font-size:0.88rem; }

        /* STAT CARDS */
        .stat-card { background:#fff; border-radius:16px; padding:1.3rem 1.5rem; box-shadow:0 2px 12px rgba(0,0,0,0.06); border:1px solid rgba(0,0,0,0.04); display:flex; align-items:center; gap:1rem; }
        .stat-icon { font-size:1.8rem; width:52px; height:52px; border-radius:14px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .stat-icon.green  { background:#e8f5ee; }
        .stat-icon.orange { background:#fff3ee; }
        .stat-icon.blue   { background:#eef3ff; }
        .stat-icon.yellow { background:#fffbe6; }
        .stat-val   { font-family:'Playfair Display',serif; font-size:1.7rem; font-weight:900; color:var(--green-dark); line-height:1; }
        .stat-label { font-size:0.78rem; color:var(--text-muted); font-weight:500; margin-top:2px; }

        /* SECTION CARD */
        .section-card { background:#fff; border-radius:18px; box-shadow:0 4px 20px rgba(0,0,0,0.07); border:1px solid rgba(0,0,0,0.04); overflow:hidden; margin-bottom:1.5rem; }
        .section-head { padding:1.1rem 1.5rem; border-bottom:2px solid var(--cream); }
        .section-head-title { font-family:'Playfair Display',serif; font-size:1.1rem; font-weight:700; color:var(--green-dark); }
        .section-body { padding:1.3rem 1.5rem; }

        /* BAR ROW */
        .bar-row { margin-bottom:0.9rem; }
        .bar-label { display:flex; justify-content:space-between; font-size:0.82rem; color:var(--text-dark); margin-bottom:4px; font-weight:500; }
        .bar-track { height:8px; background:#f0f0f0; border-radius:50px; overflow:hidden; }
        .bar-fill  { height:100%; border-radius:50px; background:linear-gradient(to right,var(--green-light),var(--green-mid)); transition:width 1s ease; }

        /* TABLE */
        .sessions-table { width:100%; border-collapse:collapse; }
        .sessions-table th { padding:0.8rem 1rem; font-size:0.75rem; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; color:var(--text-muted); background:var(--cream); text-align:left; }
        .sessions-table td { padding:0.8rem 1rem; font-size:0.82rem; color:var(--text-dark); border-bottom:1px solid #f5f5f5; }
        .sessions-table tbody tr:hover { background:#fafffe; }
        .sessions-table tbody tr:last-child td { border-bottom:none; }

        .device-mobile  { background:#e8f5ee; color:var(--green-mid); border-radius:50px; padding:0.2rem 0.6rem; font-size:0.72rem; font-weight:700; }
        .device-desktop { background:#eef3ff; color:#3a5bd9; border-radius:50px; padding:0.2rem 0.6rem; font-size:0.72rem; font-weight:700; }
        .device-tablet  { background:#fff8e6; color:#b07d00; border-radius:50px; padding:0.2rem 0.6rem; font-size:0.72rem; font-weight:700; }

        .fade-up { opacity:0; transform:translateY(16px); animation:fadeUp 0.4s forwards; }
        @keyframes fadeUp { to { opacity:1; transform:translateY(0); } }
        .footer { background:var(--green-dark); color:rgba(255,255,255,0.5); text-align:center; padding:1.2rem; font-size:0.82rem; margin-top:2rem; }
        .footer strong { color:var(--green-light); }
    </style>
</head>
<body>

<nav class="navbar-custom">
    <div class="container d-flex align-items-center justify-content-between">
        <div class="d-flex align-items-center">
            <span style="font-size:1.3rem;margin-right:6px">🌿</span>
            <span class="brand-text">Green<span class="brand-dot">Cart</span></span>
            <span class="admin-tag">Admin</span>
        </div>
        <div>
            <a href="<%=request.getContextPath()%>/views/adminhome.jsp"    class="btn-nav">📦 Products</a>
            <a href="<%=request.getContextPath()%>/views/adminorders.jsp"  class="btn-nav">🧾 Orders</a>
            <a href="<%=request.getContextPath()%>/views/adminusers.jsp"   class="btn-nav">👥 Users</a>
            <a href="<%=request.getContextPath()%>/views/home.jsp"         class="btn-nav">🌐 Store</a>
        </div>
    </div>
</nav>

<div class="page-header">
    <div class="container">
        <h1>📊 Analytics Dashboard</h1>
        <p>Track user behaviour and website performance</p>
    </div>
</div>

<div class="container py-4">

    <%-- STAT CARDS --%>
    <div class="row g-3 mb-4">
        <div class="col-6 col-md-3 fade-up">
            <div class="stat-card">
                <div class="stat-icon green">👁️</div>
                <div><div class="stat-val"><%= todaySessions %></div><div class="stat-label">Sessions Today</div></div>
            </div>
        </div>
        <div class="col-6 col-md-3 fade-up" style="animation-delay:60ms">
            <div class="stat-card">
                <div class="stat-icon blue">🌐</div>
                <div><div class="stat-val"><%= totalSessions %></div><div class="stat-label">Total Sessions</div></div>
            </div>
        </div>
        <div class="col-6 col-md-3 fade-up" style="animation-delay:120ms">
            <div class="stat-card">
                <div class="stat-icon orange">⚡</div>
                <div><div class="stat-val"><%= totalEvents %></div><div class="stat-label">Total Events</div></div>
            </div>
        </div>
        <div class="col-6 col-md-3 fade-up" style="animation-delay:180ms">
            <div class="stat-card">
                <div class="stat-icon yellow">⏱️</div>
                <div><div class="stat-val"><%= String.format("%.0f", avgTime) %>s</div><div class="stat-label">Avg Time on Page</div></div>
            </div>
        </div>
    </div>

    <div class="row g-4">

        <%-- DEVICE CHART --%>
        <div class="col-md-4 fade-up" style="animation-delay:200ms">
            <div class="section-card">
                <div class="section-head"><div class="section-head-title">📱 Device Types</div></div>
                <div class="section-body" style="display:flex;align-items:center;justify-content:center;min-height:220px;">
                    <% if (deviceMap.isEmpty()) { %>
                        <p style="color:var(--text-muted);font-size:0.85rem;text-align:center;">No data yet</p>
                    <% } else { %>
                        <canvas id="deviceChart" width="200" height="200"></canvas>
                    <% } %>
                </div>
            </div>
        </div>

        <%-- TOP PAGES --%>
        <div class="col-md-4 fade-up" style="animation-delay:260ms">
            <div class="section-card">
                <div class="section-head"><div class="section-head-title">📄 Most Visited Pages</div></div>
                <div class="section-body">
                    <% if (topPages.isEmpty()) { %>
                        <p style="color:var(--text-muted);font-size:0.85rem;">No data yet</p>
                    <% } else {
                        int maxPage = Integer.parseInt(topPages.get(0)[1]);
                        for (String[] page : topPages) {
                            int cnt = Integer.parseInt(page[1]);
                            int pct = maxPage > 0 ? (cnt * 100 / maxPage) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label">
                            <span><%= page[0] %></span>
                            <span style="color:var(--text-muted)"><%= cnt %></span>
                        </div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
        </div>

        <%-- TOP PRODUCTS CLICKED --%>
        <div class="col-md-4 fade-up" style="animation-delay:320ms">
            <div class="section-card">
                <div class="section-head"><div class="section-head-title">🔥 Most Clicked Products</div></div>
                <div class="section-body">
                    <% if (topProducts.isEmpty()) { %>
                        <p style="color:var(--text-muted);font-size:0.85rem;">No data yet</p>
                    <% } else {
                        int maxProd = Integer.parseInt(topProducts.get(0)[1]);
                        for (String[] prod : topProducts) {
                            int cnt = Integer.parseInt(prod[1]);
                            int pct = maxProd > 0 ? (cnt * 100 / maxProd) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label">
                            <span><%= prod[0] %></span>
                            <span style="color:var(--text-muted)"><%= cnt %></span>
                        </div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%;background:linear-gradient(to right,#f4a261,#e76f51)"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
        </div>

        <%-- TOP CART ADDS --%>
        <div class="col-md-6 fade-up" style="animation-delay:380ms">
            <div class="section-card">
                <div class="section-head"><div class="section-head-title">🛒 Most Added to Cart</div></div>
                <div class="section-body">
                    <% if (topCart.isEmpty()) { %>
                        <p style="color:var(--text-muted);font-size:0.85rem;">No data yet</p>
                    <% } else {
                        int maxCart = Integer.parseInt(topCart.get(0)[1]);
                        for (String[] item : topCart) {
                            int cnt = Integer.parseInt(item[1]);
                            int pct = maxCart > 0 ? (cnt * 100 / maxCart) : 0;
                    %>
                    <div class="bar-row">
                        <div class="bar-label">
                            <span><%= item[0] %></span>
                            <span style="color:var(--text-muted)"><%= cnt %> times</span>
                        </div>
                        <div class="bar-track"><div class="bar-fill" style="width:<%= pct %>%;background:linear-gradient(to right,#52b788,#1a3c2b)"></div></div>
                    </div>
                    <% } } %>
                </div>
            </div>
        </div>

        <%-- ORDERS STAT --%>
        <div class="col-md-6 fade-up" style="animation-delay:440ms">
            <div class="section-card">
                <div class="section-head"><div class="section-head-title">📦 Order Completion</div></div>
                <div class="section-body" style="display:flex;align-items:center;justify-content:center;flex-direction:column;min-height:150px;">
                    <div style="font-family:'Playfair Display',serif;font-size:3rem;font-weight:900;color:var(--green-dark)">
                        <%= totalOrders %>
                    </div>
                    <div style="color:var(--text-muted);font-size:0.88rem;margin-top:0.3rem;">Orders Placed via Website</div>
                    <div style="margin-top:1rem;background:var(--cream);border-radius:12px;padding:0.6rem 1.5rem;font-size:0.82rem;color:var(--green-mid);font-weight:600;">
                        <%= totalSessions > 0 ? String.format("%.1f", (totalOrders * 100.0 / totalSessions)) : "0.0" %>% Conversion Rate
                    </div>
                </div>
            </div>
        </div>

    </div>

    <%-- RECENT SESSIONS TABLE --%>
    <div class="section-card fade-up" style="animation-delay:500ms">
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
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                <% if (recentSessions.isEmpty()) { %>
                    <tr><td colspan="6" style="text-align:center;padding:2rem;color:var(--text-muted)">No sessions recorded yet</td></tr>
                <% } else {
                    for (Object[] s : recentSessions) {
                        String device = (String) s[2];
                        String deviceClass = "device-desktop";
                        if ("Mobile".equals(device))  deviceClass = "device-mobile";
                        if ("Tablet".equals(device))  deviceClass = "device-tablet";
                        int dur = (Integer) s[4];
                %>
                <tr>
                    <td style="font-size:0.75rem;color:var(--text-muted);font-family:monospace"><%= s[0] %></td>
                    <td style="font-weight:500"><%= s[1] %></td>
                    <td><span class="<%= deviceClass %>"><%= device %></span></td>
                    <td style="font-size:0.78rem;color:var(--text-muted)"><%= s[3] %></td>
                    <td style="font-size:0.82rem"><%= dur > 0 ? dur + "s" : "-" %></td>
                    <td style="font-size:0.78rem;color:var(--text-muted)"><%= s[5] %></td>
                </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

</div>

<div class="footer">
    <strong>Green Cart</strong> &nbsp;·&nbsp; Analytics Dashboard 🌿
</div>

<script>
<% if (!deviceMap.isEmpty()) { %>
    var ctx = document.getElementById('deviceChart').getContext('2d');
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [<%= deviceLabels %>],
            datasets: [{
                data: [<%= deviceData %>],
                backgroundColor: ['#52b788', '#3a5bd9', '#f4a261'],
                borderWidth: 0,
                hoverOffset: 8
            }]
        },
        options: {
            responsive: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { family: 'DM Sans', size: 12 }, padding: 12 }
                }
            },
            cutout: '65%'
        }
    });
<% } %>
</script>

</body>
</html>
