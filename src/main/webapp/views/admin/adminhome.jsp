<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="com.ecommerce.model.DbConnection"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        // ✅ FIXED PATH
        response.sendRedirect(request.getContextPath() + "/views/admin/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();

    int totalProducts=0, outOfStock=0, totalImages=0, totalOrders=0, totalUsers=0;
    double totalRevenue=0;
    PreparedStatement st; ResultSet rs;

    st = conn.prepareStatement("SELECT COUNT(*) FROM products");
    rs = st.executeQuery(); if(rs.next()) totalProducts=rs.getInt(1); rs.close(); st.close();

    st = conn.prepareStatement("SELECT COUNT(*) FROM products WHERE quantity=0");
    rs = st.executeQuery(); if(rs.next()) outOfStock=rs.getInt(1); rs.close(); st.close();

    st = conn.prepareStatement("SELECT COUNT(*) FROM product_images");
    rs = st.executeQuery(); if(rs.next()) totalImages=rs.getInt(1); rs.close(); st.close();

    st = conn.prepareStatement("SELECT COUNT(*) FROM orders");
    rs = st.executeQuery(); if(rs.next()) totalOrders=rs.getInt(1); rs.close(); st.close();

    st = conn.prepareStatement("SELECT COUNT(*) FROM register WHERE role='Customer'");
    rs = st.executeQuery(); if(rs.next()) totalUsers=rs.getInt(1); rs.close(); st.close();

    st = conn.prepareStatement("SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status != 'Cancelled'");
    rs = st.executeQuery(); if(rs.next()) totalRevenue=rs.getDouble(1); rs.close(); st.close();

    int pendingOrders=0;
    st = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status IN ('Pending','Processing')");
    rs = st.executeQuery(); if(rs.next()) pendingOrders=rs.getInt(1); rs.close(); st.close();

    PreparedStatement recentPs = conn.prepareStatement(
        "SELECT o.id, o.total_amount, o.status, o.created_at, o.payment_method, r.name as cname " +
        "FROM orders o LEFT JOIN register r ON o.user_id=r.id " +
        "ORDER BY o.created_at DESC LIMIT 5");
    ResultSet recentRs = recentPs.executeQuery();

    PreparedStatement prodPs = conn.prepareStatement("SELECT * FROM products ORDER BY id DESC");
    ResultSet prodRs = prodPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard — GreenCart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <style>
        :root {
            --forest:#0d2318; --pine:#153a25; --leaf:#1e5c38;
            --sage:#2d8653; --mint:#4eca7f; --frost:#d4f5e4;
            --cream:#f7f3ed; --bg:#f2f4f3; --ember:#e8603c;
            --gold:#f0a843; --sky:#3a7bd5; --ink:#0a0f0c;
            --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Instrument Sans',sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; }

        /* ── SIDEBAR ── */
        .sidebar {
            position:fixed; left:0; top:0; bottom:0;
            width:240px; background:var(--forest);
            display:flex; flex-direction:column;
            z-index:200; transition:transform 0.3s ease;
        }
        .sidebar-logo {
            padding:1.5rem 1.5rem 1rem;
            display:flex; align-items:center; gap:0.7rem;
            border-bottom:1px solid rgba(255,255,255,0.07);
            flex-shrink:0;
        }
        .logo-mark {
            width:36px; height:36px;
            background:linear-gradient(135deg,var(--mint),var(--sage));
            border-radius:10px;
            display:flex; align-items:center; justify-content:center;
            font-size:1.1rem;
        }
        .logo-txt { font-family:'Syne',sans-serif; font-weight:800; color:#fff; font-size:1.1rem; }
        .logo-txt span { color:var(--mint); }
        .admin-pill {
            background:rgba(78,202,127,0.15); color:var(--mint);
            font-size:0.6rem; font-weight:700;
            letter-spacing:1.2px; text-transform:uppercase;
            padding:0.15rem 0.5rem; border-radius:50px; margin-left:4px;
        }

        .sidebar-nav { flex:1; padding:1rem 0.8rem; overflow-y:auto; }
        .nav-section-label {
            font-size:0.65rem; font-weight:700;
            letter-spacing:1.5px; text-transform:uppercase;
            color:rgba(255,255,255,0.3);
            padding:0.8rem 0.7rem 0.4rem;
        }
        .nav-item {
            display:flex; align-items:center; gap:0.75rem;
            padding:0.65rem 0.8rem; border-radius:10px;
            color:rgba(255,255,255,0.55); text-decoration:none;
            font-size:0.88rem; font-weight:500;
            transition:all 0.2s; margin-bottom:2px;
        }
        .nav-item:hover { background:rgba(255,255,255,0.07); color:rgba(255,255,255,0.9); }
        .nav-item.active { background:rgba(78,202,127,0.15); color:var(--mint); }
        .nav-item .icon { font-size:1rem; width:20px; text-align:center; }
        .nav-badge {
            margin-left:auto; background:var(--ember); color:#fff;
            font-size:0.65rem; font-weight:700;
            padding:0.1rem 0.45rem; border-radius:50px;
            min-width:18px; text-align:center;
        }

        .sidebar-footer {
            padding:1rem;
            border-top:1px solid rgba(255,255,255,0.07);
        }
        .admin-info {
            display:flex; align-items:center; gap:0.7rem;
            padding:0.7rem; border-radius:10px;
            background:rgba(255,255,255,0.06); margin-bottom:0.5rem;
        }
        .admin-avatar {
            width:32px; height:32px;
            background:linear-gradient(135deg,var(--mint),var(--sage));
            border-radius:8px;
            display:flex; align-items:center; justify-content:center;
            font-size:0.9rem; flex-shrink:0;
        }
        .admin-name { font-size:0.82rem; font-weight:600; color:#fff; }
        .admin-role { font-size:0.68rem; color:var(--mist); }
        .btn-logout {
            display:flex; align-items:center; justify-content:center; gap:0.5rem;
            width:100%; padding:0.55rem;
            background:rgba(232,96,60,0.1); color:var(--ember);
            border:1px solid rgba(232,96,60,0.2); border-radius:8px;
            font-size:0.82rem; font-weight:600;
            text-decoration:none; transition:all 0.2s;
        }
        .btn-logout:hover { background:var(--ember); color:#fff; }

        /* ── MOBILE SIDEBAR OVERLAY ── */
        .sidebar-overlay {
            display:none; position:fixed; inset:0;
            background:rgba(0,0,0,0.5); z-index:199;
        }
        .sidebar-overlay.show { display:block; }

        /* ── MAIN ── */
        .main { margin-left:240px; min-height:100vh; transition:margin 0.3s; }

        /* ── TOPBAR ── */
        .topbar {
            background:var(--card); border-bottom:1px solid var(--border);
            padding:0.9rem 2rem;
            display:flex; align-items:center; justify-content:space-between;
            position:sticky; top:0; z-index:100;
        }
        .topbar-left { display:flex; align-items:center; gap:1rem; }
        .btn-menu {
            display:none; background:none; border:none;
            cursor:pointer; padding:0.3rem; border-radius:8px;
            color:var(--ink); transition:background 0.2s;
        }
        .btn-menu:hover { background:var(--bg); }
        .topbar-title {
            font-family:'Syne',sans-serif;
            font-size:1.15rem; font-weight:700; color:var(--ink);
        }
        .topbar-right { display:flex; align-items:center; gap:1rem; }
        .btn-view-store {
            display:flex; align-items:center; gap:0.5rem;
            background:var(--frost); color:var(--leaf);
            border:1px solid rgba(30,92,56,0.15); border-radius:8px;
            padding:0.5rem 1rem; font-size:0.82rem; font-weight:600;
            text-decoration:none; transition:all 0.2s;
        }
        .btn-view-store:hover { background:var(--leaf); color:#fff; }

        .page-content { padding:1.5rem 2rem; }

        /* ── STAT CARDS ── */
        .stats-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit,minmax(160px,1fr));
            gap:1rem; margin-bottom:1.5rem;
        }
        .stat-card {
            background:var(--card); border-radius:16px;
            padding:1.3rem 1.4rem; border:1px solid var(--border);
            box-shadow:0 1px 6px rgba(0,0,0,0.04);
            position:relative; overflow:hidden;
            animation:fadeUp 0.4s ease forwards;
        }
        .stat-card::before {
            content:''; position:absolute;
            right:-20px; top:-20px;
            width:80px; height:80px;
            border-radius:50%; opacity:0.06;
        }
        .stat-card.green::before { background:var(--mint); }
        .stat-card.orange::before { background:var(--ember); }
        .stat-card.blue::before { background:var(--sky); }
        .stat-card.gold::before { background:var(--gold); }

        .stat-icon {
            width:40px; height:40px; border-radius:10px;
            display:flex; align-items:center; justify-content:center;
            font-size:1.1rem; margin-bottom:1rem;
        }
        .stat-icon.green  { background:#e6f9ef; }
        .stat-icon.orange { background:#fff0ec; }
        .stat-icon.blue   { background:#edf3ff; }
        .stat-icon.gold   { background:#fff8e6; }

        .stat-value {
            font-family:'Syne',sans-serif;
            font-size:1.8rem; font-weight:800;
            color:var(--ink); line-height:1;
        }
        .stat-label { font-size:0.78rem; color:var(--mist); font-weight:500; margin-top:0.3rem; }
        .stat-delta {
            position:absolute; top:1.2rem; right:1.2rem;
            font-size:0.7rem; font-weight:600;
            padding:0.15rem 0.5rem; border-radius:50px;
        }
        .stat-delta.up   { background:#e6f9ef; color:var(--sage); }
        .stat-delta.warn { background:#fff0ec; color:var(--ember); }

        /* ── SECTION CARD ── */
        .sc {
            background:var(--card); border-radius:16px;
            border:1px solid var(--border);
            box-shadow:0 1px 6px rgba(0,0,0,0.04);
            overflow:hidden; margin-bottom:1.5rem;
            animation:fadeUp 0.4s ease forwards;
        }
        .sc-head {
            padding:1rem 1.5rem; border-bottom:1px solid var(--border);
            display:flex; align-items:center; justify-content:space-between;
        }
        .sc-title { font-family:'Syne',sans-serif; font-size:0.95rem; font-weight:700; color:var(--ink); }
        .sc-body { padding:1.5rem; }

        /* ── FORM ── */
        .form-label { font-size:0.78rem; font-weight:600; color:var(--ink); margin-bottom:0.35rem; }
        .form-control, .form-select {
            border:1.5px solid var(--border) !important;
            border-radius:10px !important;
            padding:0.65rem 0.9rem !important;
            font-size:0.88rem !important;
            font-family:'Instrument Sans',sans-serif !important;
            transition:all 0.2s !important;
        }
        .form-control:focus, .form-select:focus {
            border-color:var(--sage) !important;
            box-shadow:0 0 0 3px rgba(45,134,83,0.1) !important;
        }
        .divider-line { border:none; border-top:1.5px solid var(--border); margin:1.2rem 0; }

        .btn-primary-gc {
            background:var(--forest); color:#fff; border:none;
            border-radius:10px; padding:0.7rem 1.8rem;
            font-size:0.88rem; font-weight:600;
            font-family:'Instrument Sans',sans-serif;
            cursor:pointer; transition:all 0.2s;
            display:inline-flex; align-items:center; gap:0.5rem;
        }
        .btn-primary-gc:hover { background:var(--leaf); transform:translateY(-1px); }

        /* ── TABLE ── */
        .gc-table { width:100%; border-collapse:collapse; }
        .gc-table thead tr { background:#f8faf9; }
        .gc-table th {
            padding:0.75rem 1rem; font-size:0.72rem;
            font-weight:700; text-transform:uppercase;
            letter-spacing:0.8px; color:var(--mist);
            text-align:left; border-bottom:1px solid var(--border);
            white-space:nowrap;
        }
        .gc-table td {
            padding:0.9rem 1rem; font-size:0.87rem;
            border-bottom:1px solid #f0f4f2; vertical-align:middle;
        }
        .gc-table tbody tr:hover { background:#fafffe; }
        .gc-table tbody tr:last-child td { border-bottom:none; }

        /* ── BADGES ── */
        .badge-id { font-size:0.72rem; font-weight:600; background:#f2f4f3; color:var(--mist); padding:0.18rem 0.5rem; border-radius:6px; font-family:monospace; }
        .badge-name { font-weight:600; color:var(--ink); }
        .badge-price { font-weight:700; color:var(--sage); }
        .badge-stock-ok  { background:#e6f9ef; color:var(--sage); font-size:0.75rem; font-weight:600; padding:0.2rem 0.6rem; border-radius:50px; white-space:nowrap; }
        .badge-stock-low { background:#fff8e6; color:#b07d00; font-size:0.75rem; font-weight:600; padding:0.2rem 0.6rem; border-radius:50px; white-space:nowrap; }
        .badge-stock-out { background:#fff0ec; color:var(--ember); font-size:0.75rem; font-weight:600; padding:0.2rem 0.6rem; border-radius:50px; white-space:nowrap; }

        .ord-pending    { background:#fff8e6; color:#b07d00; font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #f0d080; white-space:nowrap; }
        .ord-processing { background:#edf3ff; color:var(--sky); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #c0cef5; white-space:nowrap; }
        .ord-delivered  { background:#e6f9ef; color:var(--sage); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #b8dfc9; white-space:nowrap; }
        .ord-cancelled  { background:#fff0ec; color:var(--ember); font-size:0.72rem; font-weight:700; padding:0.2rem 0.65rem; border-radius:50px; border:1px solid #ffc4b5; white-space:nowrap; }

        .btn-edit-sm {
            background:#fff8e6; color:#b07d00; border:1px solid #f0d080;
            border-radius:7px; padding:0.3rem 0.7rem;
            font-size:0.75rem; font-weight:600; cursor:pointer;
            transition:all 0.15s; font-family:'Instrument Sans',sans-serif;
        }
        .btn-edit-sm:hover { background:#f0d080; }
        .btn-del-sm {
            background:#fff0ec; color:var(--ember); border:1px solid #ffc4b5;
            border-radius:7px; padding:0.3rem 0.7rem;
            font-size:0.75rem; font-weight:600; cursor:pointer;
            transition:all 0.15s; font-family:'Instrument Sans',sans-serif;
        }
        .btn-del-sm:hover { background:var(--ember); color:#fff; border-color:var(--ember); }

        /* ── MODAL ── */
        .modal-content { border-radius:18px; border:none; }
        .modal-hdr { background:var(--forest); padding:1.2rem 1.5rem; border-radius:18px 18px 0 0; display:flex; align-items:center; justify-content:space-between; }
        .modal-hdr h5 { font-family:'Syne',sans-serif; font-size:1rem; font-weight:700; color:#fff; margin:0; }
        .modal-hdr .btn-close { filter:invert(1); opacity:0.7; }
        .modal-body { padding:1.5rem; }
        .modal-footer { border-top:1px solid var(--border); padding:1rem 1.5rem; }
        .btn-modal-cancel {
            background:var(--bg); color:var(--ink);
            border:1px solid var(--border); border-radius:8px;
            padding:0.55rem 1.2rem; font-size:0.85rem; font-weight:600;
            cursor:pointer; font-family:'Instrument Sans',sans-serif;
        }
        .btn-modal-submit {
            background:var(--forest); color:#fff; border:none;
            border-radius:8px; padding:0.55rem 1.5rem;
            font-size:0.85rem; font-weight:600; cursor:pointer;
            font-family:'Instrument Sans',sans-serif; transition:all 0.2s;
        }
        .btn-modal-submit:hover { background:var(--leaf); }

        .link-all { font-size:0.8rem; color:var(--sage); font-weight:600; text-decoration:none; transition:color 0.2s; }
        .link-all:hover { color:var(--leaf); text-decoration:underline; }

        .img-upload-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:0.6rem; }
        .img-upload-grid label { font-size:0.7rem; color:var(--mist); font-weight:500; display:block; margin-bottom:0.2rem; }

        @keyframes fadeUp { from{opacity:0;transform:translateY(12px)} to{opacity:1;transform:translateY(0)} }
        .empty-state { text-align:center; padding:3rem 2rem; color:var(--mist); }
        .empty-state .icon { font-size:2.5rem; margin-bottom:0.8rem; }
        .empty-state p { font-size:0.88rem; }
        .text-muted-sm { font-size:0.75rem; color:var(--mist); }

        /* ── MOBILE RESPONSIVE ── */
        @media (max-width: 991px) {
            .sidebar { transform:translateX(-100%); }
            .sidebar.open { transform:translateX(0); }
            .main { margin-left:0; }
            .btn-menu { display:flex; }
            .topbar { padding:0.9rem 1rem; }
            .page-content { padding:1rem; }
            .stats-grid { grid-template-columns:repeat(2,1fr); gap:0.8rem; }
            .stat-value { font-size:1.4rem; }
            .img-upload-grid { grid-template-columns:repeat(2,1fr); }
            .btn-view-store span { display:none; }
        }

        @media (max-width: 576px) {
            .stats-grid { grid-template-columns:repeat(2,1fr); }
            .stat-card { padding:1rem; }
            .sc-head { flex-wrap:wrap; gap:0.5rem; }
            .sc-body { padding:1rem; }
            /* Stack form fields on mobile */
            .row.g-3 > [class*="col-md"] { flex:0 0 100%; max-width:100%; }
            .img-upload-grid { grid-template-columns:repeat(2,1fr); }
            .modal-dialog { margin:0.5rem; }
        }
    </style>
</head>
<body>

<!-- Mobile overlay -->
<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- ═══ SIDEBAR ═══ -->
<aside class="sidebar" id="sidebar">
    <div class="sidebar-logo">
        <div class="logo-mark">🌿</div>
        <div class="logo-txt">Green<span>Cart</span> <span class="admin-pill">Admin</span></div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Overview</div>
        <%-- ✅ FIXED PATH --%>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp" class="nav-item active">
            <span class="icon">📊</span> Dashboard
        </a>
        <%-- ✅ FIXED PATH --%>
        <a href="<%=request.getContextPath()%>/views/admin/adminanalytics.jsp" class="nav-item">
            <span class="icon">📈</span> Analytics
        </a>

        <div class="nav-section-label">Catalog</div>
        <a href="#products-section" class="nav-item" onclick="scrollToSection('products-section');closeSidebar()">
            <span class="icon">📦</span> Products
        </a>
        <a href="#add-product-section" class="nav-item" onclick="scrollToSection('add-product-section');closeSidebar()">
            <span class="icon">➕</span> Add Product
        </a>

        <div class="nav-section-label">Operations</div>
        <%-- ✅ FIXED PATH --%>
        <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="nav-item">
            <span class="icon">🧾</span> Orders
            <% if(pendingOrders>0) { %><span class="nav-badge"><%= pendingOrders %></span><% } %>
        </a>
        <%-- ✅ FIXED PATH --%>
        <a href="<%=request.getContextPath()%>/views/admin/adminusers.jsp" class="nav-item">
            <span class="icon">👥</span> Customers
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-info">
            <div class="admin-avatar">👤</div>
            <div>
                <div class="admin-name"><%= admin %></div>
                <div class="admin-role">Super Admin</div>
            </div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">
            <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Sign Out
        </a>
    </div>
</aside>

<!-- ═══ MAIN ═══ -->
<div class="main">

    <!-- TOPBAR -->
    <div class="topbar">
        <div class="topbar-left">
            <button class="btn-menu" id="menuBtn" onclick="toggleSidebar()">
                <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
            </button>
            <div class="topbar-title">Dashboard Overview</div>
        </div>


    </div>

    <div class="page-content">

        <!-- STAT CARDS -->
        <div class="stats-grid">
            <div class="stat-card green">
                <span class="stat-delta up">Active</span>
                <div class="stat-icon green">📦</div>
                <div class="stat-value"><%= totalProducts %></div>
                <div class="stat-label">Total Products</div>
            </div>
            <div class="stat-card orange">
                <% if(outOfStock>0) { %><span class="stat-delta warn"><%= outOfStock %> low</span><% } %>
                <div class="stat-icon orange">⚠️</div>
                <div class="stat-value"><%= outOfStock %></div>
                <div class="stat-label">Out of Stock</div>
            </div>
            <div class="stat-card blue">
                <div class="stat-icon blue">🧾</div>
                <div class="stat-value"><%= totalOrders %></div>
                <div class="stat-label">Total Orders</div>
            </div>
            <div class="stat-card gold">
                <div class="stat-icon gold">👥</div>
                <div class="stat-value"><%= totalUsers %></div>
                <div class="stat-label">Customers</div>
            </div>
            <div class="stat-card green" style="grid-column:span 2">
                <div class="stat-icon green">💰</div>
                <div class="stat-value">₹<%= String.format("%,.0f",totalRevenue) %></div>
                <div class="stat-label">Total Revenue (non-cancelled)</div>
            </div>
            <% if(pendingOrders>0) { %>
            <div class="stat-card orange">
                <div class="stat-icon orange">🔔</div>
                <div class="stat-value"><%= pendingOrders %></div>
                <div class="stat-label">Needs Attention</div>
            </div>
            <% } %>
        </div>

        <!-- RECENT ORDERS -->
        <div class="sc" style="animation-delay:0.1s">
            <div class="sc-head">
                <div class="sc-title">🧾 Recent Orders</div>
                <%-- ✅ FIXED PATH --%>
                <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="link-all">View all →</a>
            </div>
            <div style="overflow-x:auto">
                <table class="gc-table">
                    <thead>
                        <tr>
                            <th>Order</th>
                            <th>Customer</th>
                            <th>Amount</th>
                            <th class="d-none d-md-table-cell">Payment</th>
                            <th class="d-none d-md-table-cell">Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        boolean hasRecent=false;
                        while(recentRs.next()) {
                            hasRecent=true;
                            int oid=recentRs.getInt("id");
                            double oamt=recentRs.getDouble("total_amount");
                            String ostatus=recentRs.getString("status");
                            String opay=recentRs.getString("payment_method");
                            Timestamp odate=recentRs.getTimestamp("created_at");
                            String ocname=recentRs.getString("cname");
                            if(ocname==null) ocname="Guest";
                            String obadge="ord-pending";
                            if("Processing".equals(ostatus)) obadge="ord-processing";
                            if("Delivered".equals(ostatus))  obadge="ord-delivered";
                            if("Cancelled".equals(ostatus))  obadge="ord-cancelled";
                    %>
                    <tr>
                        <td><span class="badge-id">#GC-<%= oid %></span></td>
                        <td><span style="font-weight:600"><%= ocname %></span></td>
                        <td><span class="badge-price">₹<%= String.format("%.2f",oamt) %></span></td>
                        <td class="d-none d-md-table-cell"><span class="text-muted-sm"><%= opay %></span></td>
                        <td class="d-none d-md-table-cell"><span class="text-muted-sm"><%= odate!=null?odate.toString().substring(0,16):"-" %></span></td>
                        <td><span class="<%= obadge %>"><%= ostatus %></span></td>
                    </tr>
                    <%
                        }
                        recentRs.close(); recentPs.close();
                        if(!hasRecent) {
                    %>
                    <tr><td colspan="6"><div class="empty-state"><div class="icon">📭</div><p>No orders yet</p></div></td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ADD PRODUCT -->
        <div class="sc" id="add-product-section" style="animation-delay:0.15s">
            <div class="sc-head"><div class="sc-title">➕ Add New Product</div></div>
            <div class="sc-body">
                <form action="<%=request.getContextPath()%>/addProduct" method="post" enctype="multipart/form-data">
                    <div class="row g-3 mb-3">
                        <div class="col-md-5 col-12">
                            <label class="form-label">Product Name</label>
                            <input type="text" name="name" class="form-control" placeholder="e.g. Organic Spinach" required>
                        </div>
                        <div class="col-md-3 col-6">
                            <label class="form-label">Price (₹)</label>
                            <input type="number" name="price" class="form-control" placeholder="0.00" step="0.01" min="0" required>
                        </div>
                        <div class="col-md-2 col-6">
                            <label class="form-label">Quantity</label>
                            <input type="number" name="quantity" class="form-control" placeholder="0" min="0" required>
                        </div>
                        <div class="col-md-2 col-12">
                            <label class="form-label">Category</label>
                            <select name="category" class="form-select">
                                <option value="Vegetables">🥦 Vegetables</option>
                                <option value="Fruits">🍎 Fruits</option>
                                <option value="Dairy">🥛 Dairy</option>
                                <option value="Grains">🌾 Grains</option>
                                <option value="Herbs">🌿 Herbs</option>
                                <option value="Other">📦 Other</option>
                            </select>
                        </div>
                    </div>
                    <div class="col-12 mb-3">
                        <label class="form-label">Description <small class="text-muted-sm">(optional)</small></label>
                        <textarea name="description" class="form-control" rows="2" placeholder="Brief product description..."></textarea>
                    </div>
                    <hr class="divider-line">
                    <p class="form-label mb-2">Product Images <small class="text-muted-sm">(up to 8)</small></p>
                    <div class="img-upload-grid">
                        <% for(int i=1;i<=8;i++) { %>
                        <div>
                            <label>Image <%= i %></label>
                            <input type="file" name="image<%= i %>" class="form-control" accept="image/*" style="font-size:0.75rem;padding:0.35rem 0.5rem">
                        </div>
                        <% } %>
                    </div>
                    <div class="d-flex justify-content-end mt-3">
                        <button type="submit" class="btn-primary-gc">
                            <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/></svg>
                            Add Product
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- PRODUCT TABLE -->
        <div class="sc" id="products-section" style="animation-delay:0.2s">
            <div class="sc-head">
                <div class="sc-title">📦 All Products</div>
                <span class="text-muted-sm"><%= totalProducts %> product<%= totalProducts!=1?"s":"" %></span>
            </div>
            <div style="overflow-x:auto">
                <table class="gc-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Product</th>
                            <th>Price</th>
                            <th>Stock</th>
                            <th class="d-none d-md-table-cell">Images</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        while(prodRs.next()) {
                            int pid=prodRs.getInt("id");
                            String pname=prodRs.getString("name");
                            double pprice=prodRs.getDouble("price");
                            int pqty=prodRs.getInt("quantity");

                            PreparedStatement imgPs=conn.prepareStatement("SELECT COUNT(*) FROM product_images WHERE product_id=?");
                            imgPs.setInt(1,pid);
                            ResultSet imgRs=imgPs.executeQuery();
                            int imgCnt=0; if(imgRs.next()) imgCnt=imgRs.getInt(1);
                            imgRs.close(); imgPs.close();

                            String stockBadge="badge-stock-ok";
                            String stockLabel="✓ "+pqty+" in stock";
                            if(pqty==0) { stockBadge="badge-stock-out"; stockLabel="✗ Out"; }
                            else if(pqty<=5) { stockBadge="badge-stock-low"; stockLabel="⚠ "+pqty+" low"; }

                            String safeName=pname.replace("\"","&quot;").replace("'","\\'");
                    %>
                    <tr>
                        <td><span class="badge-id">#<%= pid %></span></td>
                        <td><span class="badge-name"><%= pname %></span></td>
                        <td><span class="badge-price">₹<%= String.format("%.2f",pprice) %></span></td>
                        <td><span class="<%= stockBadge %>"><%= stockLabel %></span></td>
                        <td class="d-none d-md-table-cell"><span class="text-muted-sm">🖼 <%= imgCnt %></span></td>
                        <td>
                            <button class="btn-edit-sm me-1"
                                onclick="openEdit('<%= pid %>','<%= safeName %>','<%= pprice %>','<%= pqty %>')">
                                ✏ Edit
                            </button>
                            <form action="<%=request.getContextPath()%>/deleteProduct" method="post" style="display:inline"
                                  onsubmit="return confirm('Delete \'<%= safeName %>\'?')">
                                <input type="hidden" name="productId" value="<%= pid %>">
                                <button type="submit" class="btn-del-sm">🗑</button>
                            </form>
                        </td>
                    </tr>
                    <% } prodRs.close(); prodPs.close(); conn.close(); %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</div>

<!-- EDIT MODAL -->
<div class="modal fade" id="editModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-hdr">
                <h5>✏ Edit Product</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form action="<%=request.getContextPath()%>/updateProduct" method="post" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="productId" id="eId">
                    <div class="row g-3 mb-3">
                        <div class="col-md-5 col-12">
                            <label class="form-label">Product Name</label>
                            <input type="text" name="name" id="eName" class="form-control" required>
                        </div>
                        <div class="col-md-3 col-6">
                            <label class="form-label">Price (₹)</label>
                            <input type="number" step="0.01" min="0" name="price" id="ePrice" class="form-control" required>
                        </div>
                        <div class="col-md-2 col-6">
                            <label class="form-label">Quantity</label>
                            <input type="number" min="0" name="quantity" id="eQty" class="form-control" required>
                        </div>
                        <div class="col-md-2 col-12">
                            <label class="form-label">Category</label>
                            <select name="category" class="form-select">
                                <option value="Vegetables">🥦 Vegetables</option>
                                <option value="Fruits">🍎 Fruits</option>
                                <option value="Dairy">🥛 Dairy</option>
                                <option value="Grains">🌾 Grains</option>
                                <option value="Herbs">🌿 Herbs</option>
                                <option value="Other">📦 Other</option>
                            </select>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="2"></textarea>
                    </div>
                    <hr class="divider-line">
                    <p class="form-label mb-2">Replace Images <small class="text-muted-sm">(leave empty to keep existing)</small></p>
                    <div class="img-upload-grid">
                        <% for(int i=1;i<=8;i++) { %>
                        <div>
                            <label>Image <%= i %></label>
                            <input type="file" name="image<%= i %>" class="form-control" accept="image/*" style="font-size:0.75rem;padding:0.35rem 0.5rem">
                        </div>
                        <% } %>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-modal-cancel" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn-modal-submit">✓ Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function openEdit(id,name,price,qty) {
        document.getElementById('eId').value    = id;
        document.getElementById('eName').value  = name;
        document.getElementById('ePrice').value = price;
        document.getElementById('eQty').value   = qty;
        new bootstrap.Modal(document.getElementById('editModal')).show();
    }
    function scrollToSection(id) {
        document.getElementById(id)?.scrollIntoView({behavior:'smooth',block:'start'});
    }
    function toggleSidebar() {
        document.getElementById('sidebar').classList.toggle('open');
        document.getElementById('sidebarOverlay').classList.toggle('show');
    }
    function closeSidebar() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('show');
    }
</script>
</body>
</html>
