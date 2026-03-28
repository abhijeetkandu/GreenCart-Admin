<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/admin/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();

    // Stats
    int totalOrders=0, pendingOrders=0, deliveredOrders=0, cancelledOrders=0;
    double totalRev = 0;

    PreparedStatement st; ResultSet rs;
    st = conn.prepareStatement("SELECT COUNT(*) FROM orders"); rs = st.executeQuery(); if(rs.next()) totalOrders=rs.getInt(1); rs.close(); st.close();
    st = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'"); rs = st.executeQuery(); if(rs.next()) pendingOrders=rs.getInt(1); rs.close(); st.close();
    st = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Delivered'"); rs = st.executeQuery(); if(rs.next()) deliveredOrders=rs.getInt(1); rs.close(); st.close();
    st = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Cancelled'"); rs = st.executeQuery(); if(rs.next()) cancelledOrders=rs.getInt(1); rs.close(); st.close();
    st = conn.prepareStatement("SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status='Delivered'"); rs = st.executeQuery(); if(rs.next()) totalRev=rs.getDouble(1); rs.close(); st.close();

    // Filter by status — uses PreparedStatement to avoid SQL injection
    String filterStatus = request.getParameter("status");
    if(filterStatus == null) filterStatus = "all";

    PreparedStatement ordPs;
    if("all".equals(filterStatus)) {
        ordPs = conn.prepareStatement("SELECT o.*, r.name as cname, r.email as cemail FROM orders o LEFT JOIN register r ON o.user_id=r.id ORDER BY o.created_at DESC");
    } else {
        ordPs = conn.prepareStatement("SELECT o.*, r.name as cname, r.email as cemail FROM orders o LEFT JOIN register r ON o.user_id=r.id WHERE o.status=? ORDER BY o.created_at DESC");
        ordPs.setString(1, filterStatus);
    }
    ResultSet ordRs = ordPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Orders — GreenCart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <style>
        :root {
            --forest:#0d2318; --pine:#153a25; --leaf:#1e5c38; --sage:#2d8653; --mint:#4eca7f;
            --frost:#d4f5e4; --cream:#f7f3ed; --bg:#f2f4f3; --ember:#e8603c; --gold:#f0a843;
            --sky:#3a7bd5; --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Instrument Sans',sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; }

        /* SIDEBAR */
        .sidebar { position:fixed; left:0; top:0; bottom:0; width:240px; background:var(--forest); display:flex; flex-direction:column; z-index:200; transition:transform 0.3s ease; }
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
        .nav-item .icon { font-size:1rem; width:20px; text-align:center; }
        .nav-badge { margin-left:auto; background:var(--ember); color:#fff; font-size:0.65rem; font-weight:700; padding:0.1rem 0.45rem; border-radius:50px; }
        .sidebar-footer { padding:1rem; border-top:1px solid rgba(255,255,255,0.07); }
        .admin-info { display:flex; align-items:center; gap:0.7rem; padding:0.7rem; border-radius:10px; background:rgba(255,255,255,0.06); margin-bottom:0.5rem; }
        .admin-avatar { width:32px; height:32px; background:linear-gradient(135deg,var(--mint),var(--sage)); border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:0.9rem; }
        .admin-name { font-size:0.82rem; font-weight:600; color:#fff; }
        .admin-role { font-size:0.68rem; color:var(--mist); }
        .btn-logout { display:flex; align-items:center; justify-content:center; gap:0.5rem; width:100%; padding:0.55rem; background:rgba(232,96,60,0.1); color:var(--ember); border:1px solid rgba(232,96,60,0.2); border-radius:8px; font-size:0.82rem; font-weight:600; text-decoration:none; transition:all 0.2s; }
        .btn-logout:hover { background:var(--ember); color:#fff; }

        /* OVERLAY */
        .sidebar-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.5); z-index:199; }

        .main { margin-left:240px; min-height:100vh; }
        .topbar { background:var(--card); border-bottom:1px solid var(--border); padding:0.9rem 2rem; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:100; }
        .topbar-title { font-family:'Syne',sans-serif; font-size:1.15rem; font-weight:700; color:var(--ink); }
        .btn-hamburger { display:none; background:none; border:none; font-size:1.4rem; cursor:pointer; color:var(--ink); }
        .btn-view-store { display:flex; align-items:center; gap:0.5rem; background:var(--frost); color:var(--leaf); border:1px solid rgba(30,92,56,0.15); border-radius:8px; padding:0.5rem 1rem; font-size:0.82rem; font-weight:600; text-decoration:none; transition:all 0.2s; }
        .btn-view-store:hover { background:var(--leaf); color:#fff; }
        .page-content { padding:2rem; }

        /* STATS */
        .stats-grid { display:grid; grid-template-columns:repeat(5,1fr); gap:1rem; margin-bottom:1.5rem; }
        .stat-card { background:var(--card); border-radius:14px; padding:1.2rem 1.3rem; border:1px solid var(--border); }
        .stat-value { font-family:'Syne',sans-serif; font-size:1.6rem; font-weight:800; color:var(--ink); }
        .stat-label { font-size:0.75rem; color:var(--mist); font-weight:500; margin-top:0.2rem; }

        /* FILTER TABS */
        .filter-tabs { display:flex; gap:0.5rem; margin-bottom:1.2rem; flex-wrap:wrap; }
        .filter-tab { padding:0.45rem 1.1rem; border-radius:8px; font-size:0.82rem; font-weight:600; text-decoration:none; transition:all 0.2s; border:1.5px solid var(--border); color:var(--mist); background:var(--card); }
        .filter-tab:hover { border-color:var(--sage); color:var(--sage); }
        .filter-tab.active { background:var(--forest); color:#fff; border-color:var(--forest); }

        /* TABLE */
        .sc { background:var(--card); border-radius:16px; border:1px solid var(--border); box-shadow:0 1px 6px rgba(0,0,0,0.04); overflow:hidden; }
        .sc-head { padding:1.1rem 1.5rem; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
        .sc-title { font-family:'Syne',sans-serif; font-size:0.95rem; font-weight:700; color:var(--ink); }

        .gc-table { width:100%; border-collapse:collapse; }
        .gc-table thead tr { background:#f8faf9; }
        .gc-table th { padding:0.75rem 1rem; font-size:0.7rem; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; color:var(--mist); text-align:left; border-bottom:1px solid var(--border); }
        .gc-table td { padding:0.85rem 1rem; font-size:0.85rem; border-bottom:1px solid #f0f4f2; vertical-align:middle; }
        .gc-table tbody tr:hover { background:#fafffe; }
        .gc-table tbody tr:last-child td { border-bottom:none; }

        .badge-id { font-size:0.72rem; font-weight:600; background:#f2f4f3; color:var(--mist); padding:0.18rem 0.5rem; border-radius:6px; font-family:monospace; }
        .cust-name { font-weight:600; color:var(--ink); font-size:0.85rem; }
        .cust-email { font-size:0.72rem; color:var(--mist); }
        .price-val { font-weight:700; color:var(--sage); }

        .ord-pending    { background:#fff8e6; color:#b07d00; font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #f0d080; }
        .ord-processing { background:#edf3ff; color:var(--sky); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #c0cef5; }
        .ord-delivered  { background:#e6f9ef; color:var(--sage); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #b8dfc9; }
        .ord-cancelled  { background:#fff0ec; color:var(--ember); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #ffc4b5; }

        .status-sel { border:1.5px solid var(--border); border-radius:7px; padding:0.3rem 0.5rem; font-size:0.78rem; font-family:'Instrument Sans',sans-serif; cursor:pointer; }
        .status-sel:focus { border-color:var(--sage); outline:none; }
        .btn-upd { background:var(--forest); color:#fff; border:none; border-radius:7px; padding:0.3rem 0.75rem; font-size:0.75rem; font-weight:600; cursor:pointer; transition:all 0.2s; font-family:'Instrument Sans',sans-serif; }
        .btn-upd:hover { background:var(--leaf); }

        .text-muted-sm { font-size:0.75rem; color:var(--mist); }
        .empty-state { text-align:center; padding:3rem 2rem; color:var(--mist); }
        .empty-state .icon { font-size:2.5rem; margin-bottom:0.8rem; }

        @keyframes fadeUp { from{opacity:0;transform:translateY(12px)} to{opacity:1;transform:translateY(0)} }
        .sc { animation:fadeUp 0.3s ease forwards; }

        /* ── MOBILE RESPONSIVE ── */
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
            .sidebar-overlay.open { display:block; }
            .main { margin-left: 0; }
            .btn-hamburger { display:block; }
            .page-content { padding: 1rem; }
            .topbar { padding: 0.75rem 1rem; }
            .stats-grid { grid-template-columns: repeat(2,1fr); }
            .stats-grid .stat-card:last-child { grid-column: span 2; }
            .filter-tabs { gap: 0.3rem; }
            .filter-tab { padding: 0.35rem 0.7rem; font-size: 0.75rem; }
            /* Hide less-important columns on mobile */
            .gc-table th:nth-child(3),
            .gc-table td:nth-child(3),
            .gc-table th:nth-child(6),
            .gc-table td:nth-child(6),
            .gc-table th:nth-child(7),
            .gc-table td:nth-child(7) { display: none; }
            .gc-table th, .gc-table td { padding: 0.6rem 0.5rem; font-size: 0.78rem; }
            .status-sel { font-size: 0.72rem; padding: 0.25rem 0.3rem; }
        }
        @media (max-width: 480px) {
            .stats-grid { grid-template-columns: 1fr 1fr; }
            .stat-value { font-size: 1.2rem; }
            /* Also hide payment on very small screens */
            .gc-table th:nth-child(5),
            .gc-table td:nth-child(5) { display: none; }
        }
    </style>
</head>
<body>

<!-- SIDEBAR OVERLAY -->
<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- SIDEBAR -->
<aside class="sidebar" id="sidebar">
    <div class="sidebar-logo">
        <div class="logo-mark">🌿</div>
        <div class="logo-txt">Green<span>Cart</span> <span class="admin-pill">Admin</span></div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Overview</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp" class="nav-item"><span class="icon">📊</span> Dashboard</a>
        <div class="nav-section-label">Catalog</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp#products-section" class="nav-item"><span class="icon">📦</span> Products</a>
        <div class="nav-section-label">Operations</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="nav-item active"><span class="icon">🧾</span> Orders
            <% if(pendingOrders > 0) { %><span class="nav-badge"><%= pendingOrders %></span><% } %>
        </a>
        <a href="<%=request.getContextPath()%>/views/admin/adminusers.jsp" class="nav-item"><span class="icon">👥</span> Customers</a>
        <a href="<%=request.getContextPath()%>/views/admin/adminanalytics.jsp" class="nav-item"><span class="icon">📈</span> Analytics</a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-info">
            <div class="admin-avatar">👤</div>
            <div><div class="admin-name"><%= admin %></div><div class="admin-role">Super Admin</div></div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div style="display:flex;align-items:center;gap:0.75rem;">
            <button class="btn-hamburger" onclick="openSidebar()">☰</button>
            <div class="topbar-title">🧾 Manage Orders</div>
        </div>
        <a href="<%=request.getContextPath()%>/views/user/home.jsp" class="btn-view-store" target="_blank">🌐 View Store</a>
    </div>

    <div class="page-content">

        <!-- STATS -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value"><%= totalOrders %></div>
                <div class="stat-label">Total Orders</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:#b07d00"><%= pendingOrders %></div>
                <div class="stat-label">Pending</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:var(--sage)"><%= deliveredOrders %></div>
                <div class="stat-label">Delivered</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:var(--ember)"><%= cancelledOrders %></div>
                <div class="stat-label">Cancelled</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:var(--sage)">₹<%= String.format("%,.0f", totalRev) %></div>
                <div class="stat-label">Revenue (Delivered)</div>
            </div>
        </div>

        <!-- FILTER TABS -->
        <div class="filter-tabs">
            <a href="?status=all"        class="filter-tab <%= "all".equals(filterStatus)        ? "active" : "" %>">All Orders</a>
            <a href="?status=Pending"    class="filter-tab <%= "Pending".equals(filterStatus)    ? "active" : "" %>">⏳ Pending</a>
            <a href="?status=Processing" class="filter-tab <%= "Processing".equals(filterStatus) ? "active" : "" %>">🔄 Processing</a>
            <a href="?status=Delivered"  class="filter-tab <%= "Delivered".equals(filterStatus)  ? "active" : "" %>">✅ Delivered</a>
            <a href="?status=Cancelled"  class="filter-tab <%= "Cancelled".equals(filterStatus)  ? "active" : "" %>">❌ Cancelled</a>
        </div>

        <!-- ORDERS TABLE -->
        <div class="sc">
            <div class="sc-head">
                <div class="sc-title">Orders</div>
            </div>
            <div style="overflow-x:auto">
                <table class="gc-table">
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>Customer</th>
                            <th>Items</th>
                            <th>Total</th>
                            <th>Payment</th>
                            <th>City</th>
                            <th>Date</th>
                            <th>Status</th>
                            <th>Update</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        boolean hasOrders = false;
                        while(ordRs.next()) {
                            hasOrders = true;
                            int oid         = ordRs.getInt("id");
                            double oamt     = ordRs.getDouble("total_amount");
                            String ostatus  = ordRs.getString("status");
                            String ocity    = ordRs.getString("city");
                            String opay     = ordRs.getString("payment_method");
                            Timestamp odate = ordRs.getTimestamp("created_at");
                            String ocname   = ordRs.getString("cname");
                            String ocemail  = ordRs.getString("cemail");
                            if(ocname == null) ocname = "Guest";
                            if(ocemail == null) ocemail = "";

                            PreparedStatement cntPs = conn.prepareStatement("SELECT COUNT(*) FROM order_items WHERE order_id=?");
                            cntPs.setInt(1, oid);
                            ResultSet cntRs = cntPs.executeQuery();
                            int itemCnt = 0;
                            if(cntRs.next()) itemCnt = cntRs.getInt(1);
                            cntRs.close(); cntPs.close();

                            String obadge = "ord-pending";
                            if("Processing".equals(ostatus)) obadge = "ord-processing";
                            if("Delivered".equals(ostatus))  obadge = "ord-delivered";
                            if("Cancelled".equals(ostatus))  obadge = "ord-cancelled";
                    %>
                    <tr>
                        <td><span class="badge-id">#GC-<%= oid %></span></td>
                        <td>
                            <div class="cust-name"><%= ocname %></div>
                            <div class="cust-email"><%= ocemail %></div>
                        </td>
                        <td><span class="text-muted-sm"><%= itemCnt %> item(s)</span></td>
                        <td><span class="price-val">₹<%= String.format("%.2f", oamt) %></span></td>
                        <td><span class="text-muted-sm"><%= opay %></span></td>
                        <td><span class="text-muted-sm">📍 <%= ocity != null ? ocity : "-" %></span></td>
                        <td><span class="text-muted-sm"><%= odate != null ? odate.toString().substring(0,16) : "-" %></span></td>
                        <td><span class="<%= obadge %>"><%= ostatus %></span></td>
                        <td>
                            <form action="<%=request.getContextPath()%>/updateOrderStatus" method="post" style="display:flex; gap:4px; align-items:center;">
                                <input type="hidden" name="orderId" value="<%= oid %>">
                                <select name="status" class="status-sel">
                                    <option value="Pending"    <%= "Pending".equals(ostatus)    ? "selected" : "" %>>Pending</option>
                                    <option value="Processing" <%= "Processing".equals(ostatus) ? "selected" : "" %>>Processing</option>
                                    <option value="Delivered"  <%= "Delivered".equals(ostatus)  ? "selected" : "" %>>Delivered</option>
                                    <option value="Cancelled"  <%= "Cancelled".equals(ostatus)  ? "selected" : "" %>>Cancelled</option>
                                </select>
                                <button type="submit" class="btn-upd">✓</button>
                            </form>
                        </td>
                    </tr>
                    <%
                        }
                        ordRs.close(); ordPs.close(); conn.close();
                        if(!hasOrders) {
                    %>
                    <tr><td colspan="9"><div class="empty-state"><div class="icon">📭</div><p>No orders found for this filter.</p></div></td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</div>

<script>
    function openSidebar()  { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebarOverlay').classList.add('open'); }
    function closeSidebar() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebarOverlay').classList.remove('open'); }
</script>
</body>
</html>
