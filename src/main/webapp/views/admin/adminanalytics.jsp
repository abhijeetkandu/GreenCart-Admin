<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/admin/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();
    PreparedStatement ps; ResultSet rs;

    ps = conn.prepareStatement(
        "SELECT COALESCE(AVG(time_on_page), 0) FROM user_events " +
        "WHERE event_type IN ('time_on_page','time_spent') AND time_on_page > 0");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders");
    rs = ps.executeQuery();
    int totalOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    int pendingOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Delivered'");
    rs = ps.executeQuery();
    int deliveredOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Cancelled'");
    rs = ps.executeQuery();
    int cancelledOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement(
        "SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status='Delivered'");
    rs = ps.executeQuery();
    double totalRevenue = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement(
        "SELECT page_url, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' AND page_url IS NOT NULL AND page_url != '' " +
        "GROUP BY page_url ORDER BY cnt DESC LIMIT 8");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while (rs.next()) {
        String rawUrl = rs.getString("page_url");
        String niceName = rawUrl;
        if (rawUrl.contains("/")) {
            niceName = rawUrl.substring(rawUrl.lastIndexOf("/") + 1);
        }
        niceName = niceName.replace(".jsp", "").replace("-", " ");
        niceName = niceName.substring(0, 1).toUpperCase() + niceName.substring(1);
        if (rawUrl.contains("home"))     niceName = "🏠 Home";
        if (rawUrl.contains("cart"))     niceName = "🛒 Cart";
        if (rawUrl.contains("checkout")) niceName = "💳 Checkout";
        if (rawUrl.contains("login"))    niceName = "🔐 Login";
        if (rawUrl.contains("register")) niceName = "📝 Register";
        if (rawUrl.contains("orders"))   niceName = "📦 Orders";
        if (rawUrl.contains("profile"))  niceName = "👤 Profile";
        topPages.add(new String[]{niceName, rawUrl, String.valueOf(rs.getInt("cnt"))});
    }
    rs.close(); ps.close();

    ps = conn.prepareStatement(
        "SELECT page_url, ROUND(AVG(time_on_page)) as avg_time FROM user_events " +
        "WHERE event_type IN ('time_on_page','time_spent') AND time_on_page > 0 " +
        "GROUP BY page_url ORDER BY avg_time DESC LIMIT 5");
    rs = ps.executeQuery();
    List<String[]> timePerPage = new ArrayList<>();
    while (rs.next()) {
        String rawUrl  = rs.getString("page_url");
        String niceName = rawUrl;
        if (rawUrl.contains("home"))     niceName = "🏠 Home";
        if (rawUrl.contains("cart"))     niceName = "🛒 Cart";
        if (rawUrl.contains("checkout")) niceName = "💳 Checkout";
        if (rawUrl.contains("login"))    niceName = "🔐 Login";
        if (rawUrl.contains("register")) niceName = "📝 Register";
        if (rawUrl.contains("orders"))   niceName = "📦 Orders";
        timePerPage.add(new String[]{niceName, String.valueOf(rs.getInt("avg_time"))});
    }
    rs.close(); ps.close();

    conn.close();

    int completedOrders = totalOrders - pendingOrders - cancelledOrders;
    if (completedOrders < 0) completedOrders = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics – GreenCart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --forest:#0d2318; --pine:#153a25; --leaf:#1e5c38; --sage:#2d8653; --mint:#4eca7f;
            --frost:#d4f5e4; --bg:#f2f4f3; --ember:#e8603c; --gold:#f0a843;
            --sky:#3a7bd5; --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        *, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }
        html { overflow-x: hidden; }
        body { font-family:'Instrument Sans',sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; overflow-x:hidden; }

        /* ── SIDEBAR ── */
        .sidebar {
            width: 230px;
            background: var(--forest);
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; bottom: 0; left: 0;
            z-index: 300;
            transition: transform 0.3s ease;
            overflow-y: auto;
        }
        .sb-logo { padding:1.4rem 1.2rem 1rem; display:flex; align-items:center; gap:0.6rem; border-bottom:1px solid rgba(255,255,255,0.07); flex-shrink:0; }
        .sb-mark { width:34px; height:34px; min-width:34px; background:linear-gradient(135deg,var(--mint),var(--sage)); border-radius:9px; display:flex; align-items:center; justify-content:center; font-size:1rem; }
        .sb-txt { font-family:'Syne',sans-serif; font-weight:800; color:#fff; font-size:1rem; white-space:nowrap; }
        .sb-txt span { color:var(--mint); }
        .sb-pill { background:rgba(78,202,127,0.15); color:var(--mint); font-size:0.58rem; font-weight:700; letter-spacing:1px; text-transform:uppercase; padding:0.12rem 0.45rem; border-radius:50px; margin-left:3px; }
        .sb-nav { flex:1; padding:0.8rem; overflow-y:auto; }
        .sb-lbl { font-size:0.62rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:rgba(255,255,255,0.28); padding:0.7rem 0.6rem 0.35rem; }
        .sb-item { display:flex; align-items:center; gap:0.7rem; padding:0.6rem 0.75rem; border-radius:9px; color:rgba(255,255,255,0.5); text-decoration:none; font-size:0.85rem; font-weight:500; transition:all 0.18s; margin-bottom:1px; }
        .sb-item:hover { background:rgba(255,255,255,0.07); color:rgba(255,255,255,0.9); }
        .sb-item.active { background:rgba(78,202,127,0.14); color:var(--mint); }
        .sb-badge { margin-left:auto; background:var(--ember); color:#fff; font-size:0.62rem; font-weight:700; padding:0.08rem 0.42rem; border-radius:50px; }
        .sb-foot { padding:0.9rem; border-top:1px solid rgba(255,255,255,0.07); flex-shrink:0; }
        .sb-user { display:flex; align-items:center; gap:0.65rem; padding:0.65rem; border-radius:9px; background:rgba(255,255,255,0.05); margin-bottom:0.5rem; min-width:0; }
        .sb-av { width:30px; height:30px; min-width:30px; background:linear-gradient(135deg,var(--mint),var(--sage)); border-radius:7px; display:flex; align-items:center; justify-content:center; font-size:0.85rem; }
        .sb-name { font-size:0.8rem; font-weight:600; color:#fff; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .sb-role { font-size:0.65rem; color:var(--mist); }
        .btn-logout { display:flex; align-items:center; justify-content:center; gap:0.4rem; width:100%; padding:0.5rem; background:rgba(232,96,60,0.1); color:var(--ember); border:1px solid rgba(232,96,60,0.2); border-radius:8px; font-size:0.8rem; font-weight:600; text-decoration:none; transition:all 0.2s; }
        .btn-logout:hover { background:var(--ember); color:#fff; }

        /* Overlay */
        .sb-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.55); z-index:299; }
        .sb-overlay.show { display:block; }

        /* ── MAIN ── */
        .main { margin-left:230px; min-height:100vh; display:flex; flex-direction:column; min-width:0; }

        /* ── TOPBAR ── */
        .topbar { background:var(--card); border-bottom:1px solid var(--border); padding:0.85rem 1.8rem; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:100; gap:0.75rem; }
        .tb-left { display:flex; align-items:center; gap:1rem; min-width:0; }
        .btn-menu { display:none; background:none; border:none; cursor:pointer; padding:0.3rem; border-radius:8px; color:var(--ink); flex-shrink:0; }
        .tb-title { font-family:'Syne',sans-serif; font-size:1.1rem; font-weight:700; white-space:nowrap; }

        /* ── CONTENT ── */
        .content { padding:1.8rem; flex:1; display:flex; flex-direction:column; gap:1.4rem; min-width:0; overflow-x:hidden; }

        /* ── HERO ── */
        .hero { background:linear-gradient(135deg,var(--forest) 0%,var(--pine) 50%,#1a4a2e 100%); border-radius:20px; padding:2rem 2.2rem; display:flex; align-items:center; justify-content:space-between; gap:1.5rem; position:relative; overflow:hidden; flex-wrap:wrap; }
        .hero::before { content:''; position:absolute; top:-40px; right:-40px; width:220px; height:220px; background:radial-gradient(circle,rgba(78,202,127,0.15) 0%,transparent 70%); border-radius:50%; pointer-events:none; }
        .hero-left { min-width:0; }
        .hero-eyebrow { font-size:0.68rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:var(--mint); margin-bottom:0.5rem; }
        .hero-title { font-family:'Syne',sans-serif; font-size:1.6rem; font-weight:800; color:#fff; line-height:1.2; margin-bottom:0.6rem; }
        .hero-sub { font-size:0.85rem; color:rgba(255,255,255,0.5); max-width:340px; line-height:1.5; }
        .hero-right { display:flex; align-items:center; gap:1.5rem; position:relative; z-index:1; flex-wrap:wrap; }
        .hero-stat { text-align:center; }
        .hero-stat-val { font-family:'Syne',sans-serif; font-size:2.4rem; font-weight:800; color:#fff; line-height:1; }
        .hero-stat-val.green { color:var(--mint); }
        .hero-stat-val.gold { color:var(--gold); }
        .hero-stat-lbl { font-size:0.7rem; color:rgba(255,255,255,0.45); margin-top:0.3rem; font-weight:500; white-space:nowrap; }
        .hero-divider { width:1px; height:50px; background:rgba(255,255,255,0.12); }

        /* ── REVENUE STRIP ── */
        .rev-strip { background:linear-gradient(90deg,var(--leaf),var(--sage)); border-radius:16px; padding:1.3rem 1.8rem; display:flex; align-items:center; justify-content:space-between; gap:1rem; flex-wrap:wrap; }
        .rev-label { font-size:0.8rem; color:rgba(255,255,255,0.7); font-weight:500; margin-bottom:0.25rem; }
        .rev-value { font-family:'Syne',sans-serif; font-size:1.9rem; font-weight:800; color:#fff; }
        .rev-badge { background:rgba(255,255,255,0.15); border:1px solid rgba(255,255,255,0.25); color:#fff; border-radius:50px; padding:0.35rem 1rem; font-size:0.78rem; font-weight:600; white-space:nowrap; }

        /* ── ORDER STATUS ── */
        .status-row { display:grid; grid-template-columns:repeat(4,1fr); gap:1rem; }
        .status-card { background:var(--card); border-radius:16px; border:1px solid var(--border); padding:1.3rem 1.4rem; display:flex; flex-direction:column; gap:0.55rem; position:relative; overflow:hidden; transition:transform 0.2s,box-shadow 0.2s; }
        .status-card:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(0,0,0,0.08); }
        .status-card::before { content:''; position:absolute; top:0; left:0; right:0; height:3px; border-radius:16px 16px 0 0; }
        .status-card.all::before { background:linear-gradient(90deg,var(--mint),var(--sage)); }
        .status-card.pending::before { background:var(--gold); }
        .status-card.done::before { background:var(--sage); }
        .status-card.cancelled::before { background:var(--ember); }
        .status-icon { font-size:1.4rem; }
        .status-val { font-family:'Syne',sans-serif; font-size:1.9rem; font-weight:800; color:var(--ink); }
        .status-val.gold { color:#b07d00; }
        .status-val.green { color:var(--sage); }
        .status-val.red { color:var(--ember); }
        .status-lbl { font-size:0.75rem; color:var(--mist); font-weight:500; }

        /* ── BOTTOM ROW ── */
        .bottom-row { display:grid; grid-template-columns:1fr 1fr; gap:1.4rem; align-items:start; }
        .bottom-right-col { display:flex; flex-direction:column; gap:1.4rem; }

        /* ── CARD ── */
        .card { background:var(--card); border-radius:16px; border:1px solid var(--border); box-shadow:0 1px 4px rgba(0,0,0,0.04); overflow:hidden; }
        .ch { padding:1rem 1.4rem; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
        .ch-title { font-family:'Syne',sans-serif; font-size:0.9rem; font-weight:700; }
        .ch-badge { background:var(--frost); color:var(--leaf); font-size:0.68rem; font-weight:700; padding:0.18rem 0.6rem; border-radius:50px; white-space:nowrap; }
        .cb { padding:1.2rem 1.4rem; }

        /* ── PAGE ROWS ── */
        .page-row { display:flex; align-items:center; gap:0.85rem; padding:0.65rem 0; border-bottom:1px solid #f5f7f5; }
        .page-row:last-child { border-bottom:none; }
        .page-rank { width:24px; height:24px; min-width:24px; border-radius:7px; background:var(--bg); display:flex; align-items:center; justify-content:center; font-size:0.7rem; font-weight:700; color:var(--mist); }
        .page-rank.top { background:linear-gradient(135deg,var(--mint),var(--sage)); color:#fff; }
        .page-info { flex:1; min-width:0; }
        .page-name { font-size:0.85rem; font-weight:600; color:var(--ink); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .page-url-small { font-size:0.7rem; color:var(--mist); margin-top:1px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .page-bar-bg { height:5px; background:#f0f0f0; border-radius:50px; overflow:hidden; margin-top:5px; }
        .page-bar-fill { height:100%; border-radius:50px; background:linear-gradient(to right,var(--mint),var(--sage)); transition:width 1s ease; }
        .page-count { font-size:0.8rem; font-weight:700; color:var(--sage); flex-shrink:0; white-space:nowrap; }

        /* ── TIME PER PAGE ── */
        .time-row { display:flex; align-items:center; gap:0.75rem; padding:0.7rem 0; border-bottom:1px solid #f5f7f5; }
        .time-row:last-child { border-bottom:none; }
        .time-page-name { font-size:0.83rem; font-weight:600; color:var(--ink); min-width:90px; flex-shrink:0; }
        .time-bar-wrap { flex:1; min-width:0; }
        .time-bar-bg { height:6px; background:#f0f0f0; border-radius:50px; overflow:hidden; }
        .time-bar-fill { height:100%; border-radius:50px; background:linear-gradient(to right,var(--gold),var(--ember)); transition:width 1s ease; }
        .time-val-badge { font-size:0.82rem; font-weight:700; color:#b07d00; flex-shrink:0; white-space:nowrap; }

        /* ── AVG TIME RING ── */
        .time-card { background:var(--card); border-radius:16px; border:1px solid var(--border); padding:1.6rem 1.4rem; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; gap:0.9rem; }
        .time-ring { width:130px; height:130px; border-radius:50%; display:flex; align-items:center; justify-content:center; position:relative; flex-shrink:0; }
        .time-ring-inner { width:92px; height:92px; border-radius:50%; background:var(--card); display:flex; flex-direction:column; align-items:center; justify-content:center; gap:2px; position:absolute; }
        .time-big { font-family:'Syne',sans-serif; font-size:1.6rem; font-weight:800; color:var(--ink); line-height:1; }
        .time-unit { font-size:0.62rem; color:var(--mist); font-weight:600; letter-spacing:1px; text-transform:uppercase; }
        .time-title { font-family:'Syne',sans-serif; font-size:0.9rem; font-weight:700; }
        .time-tip { background:var(--frost); border-radius:10px; padding:0.65rem 0.9rem; font-size:0.75rem; color:var(--leaf); font-weight:500; width:100%; line-height:1.5; text-align:center; }

        .empty { color:var(--mist); font-size:0.82rem; text-align:center; padding:2.5rem 0; }

        /* ── ANIMATIONS ── */
        @keyframes fadeUp { from { opacity:0; transform:translateY(14px); } to { opacity:1; transform:translateY(0); } }
        .hero { animation:fadeUp 0.35s ease forwards; }
        .rev-strip, .status-row, .bottom-row { animation:fadeUp 0.4s ease 0.1s forwards; opacity:0; }

        /* ── RESPONSIVE ── */
        @media (max-width: 1024px) {
            .status-row { grid-template-columns: repeat(2, 1fr); }
        }

        @media (max-width: 900px) {
            /* Sidebar slides off-screen on mobile */
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }

            /* Main takes full width */
            .main { margin-left: 0; }
            .btn-menu { display: flex; }

            .content { padding: 1rem; gap: 1rem; }

            /* Hero stacks vertically */
            .hero { flex-direction: column; align-items: flex-start; padding: 1.5rem; }
            .hero-right { width: 100%; justify-content: space-between; gap: 0.75rem; }
            .hero-stat-val { font-size: 1.9rem; }
            .hero-divider { height: 40px; }

            /* Revenue strip stacks */
            .rev-strip { padding: 1.1rem 1.4rem; }
            .rev-value { font-size: 1.6rem; }

            /* Bottom row stacks */
            .bottom-row { grid-template-columns: 1fr; }
        }

        @media (max-width: 600px) {
            .topbar { padding: 0.75rem 1rem; }
            .content { padding: 0.85rem; gap: 0.9rem; }

            /* Status cards: 2 columns on small screens */
            .status-row { grid-template-columns: repeat(2, 1fr); gap: 0.75rem; }
            .status-val { font-size: 1.6rem; }

            /* Hero stats wrap nicely */
            .hero { padding: 1.2rem; }
            .hero-title { font-size: 1.35rem; }
            .hero-right { gap: 0.5rem; }
            .hero-stat-val { font-size: 1.6rem; }

            /* Cards: reduce padding */
            .cb { padding: 1rem; }
            .ch { padding: 0.85rem 1rem; }

            /* Time page name shorter on tiny screens */
            .time-page-name { min-width: 70px; font-size: 0.78rem; }

            /* Revenue strip */
            .rev-strip { flex-direction: column; align-items: flex-start; gap: 0.6rem; padding: 1rem 1.2rem; }
            .rev-badge { align-self: flex-start; }
        }

        @media (max-width: 400px) {
            .status-row { grid-template-columns: repeat(2, 1fr); gap: 0.6rem; }
            .hero-right { justify-content: space-around; }
            .hero-divider { display: none; }
            .hero-stat-val { font-size: 1.5rem; }
        }
    </style>
</head>
<body>

<div class="sb-overlay" id="sbOverlay" onclick="closeSb()"></div>

<aside class="sidebar" id="sidebar">
    <div class="sb-logo">
        <div class="sb-mark">🌿</div>
        <div class="sb-txt">Green<span>Cart</span><span class="sb-pill">Admin</span></div>
    </div>
    <nav class="sb-nav">
        <div class="sb-lbl">Overview</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp" class="sb-item"><span>🏠</span> Dashboard</a>
        <a href="<%=request.getContextPath()%>/views/admin/adminanalytics.jsp" class="sb-item active"><span>📈</span> Analytics</a>
        <div class="sb-lbl">Operations</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="sb-item">
            <span>🧾</span> Orders
            <%if(pendingOrders>0){%><span class="sb-badge"><%=pendingOrders%></span><%}%>
        </a>
        <a href="<%=request.getContextPath()%>/views/admin/adminusers.jsp" class="sb-item"><span>👥</span> Customers</a>
    </nav>
    <div class="sb-foot">
        <div class="sb-user">
            <div class="sb-av">👤</div>
            <div style="min-width:0;">
                <div class="sb-name"><%= admin %></div>
                <div class="sb-role">Super Admin</div>
            </div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">🚪 Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div class="tb-left">
            <button class="btn-menu" onclick="toggleSb()" aria-label="Toggle menu">
                <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
            </button>
            <div class="tb-title">📈 Analytics</div>
        </div>
    </div>

    <div class="content">

        <%-- HERO --%>
        <div class="hero">
            <div class="hero-left">
                <div class="hero-eyebrow">GreenCart · Store Overview</div>
                <div class="hero-title">Your store at<br>a glance 🌿</div>
                <div class="hero-sub">Real-time order data and page engagement metrics.</div>
            </div>
            <div class="hero-right">
                <div class="hero-stat">
                    <div class="hero-stat-val green"><%= totalOrders %></div>
                    <div class="hero-stat-lbl">Total Orders</div>
                </div>
                <div class="hero-divider"></div>
                <div class="hero-stat">
                    <div class="hero-stat-val gold"><%= pendingOrders %></div>
                    <div class="hero-stat-lbl">Pending</div>
                </div>
                <div class="hero-divider"></div>
                <div class="hero-stat">
                    <div class="hero-stat-val"><%= String.format("%.0f", avgTime) %>s</div>
                    <div class="hero-stat-lbl">Avg Time/Page</div>
                </div>
            </div>
        </div>

        <%-- REVENUE STRIP --%>
        <div class="rev-strip">
            <div>
                <div class="rev-label">💰 Total Revenue from Delivered Orders</div>
                <div class="rev-value">₹<%= String.format("%,.0f", totalRevenue) %></div>
            </div>
            <div class="rev-badge">✅ <%= deliveredOrders %> orders delivered</div>
        </div>

        <%-- ORDER STATUS CARDS --%>
        <div class="status-row">
            <div class="status-card all">
                <div class="status-icon">🧾</div>
                <div class="status-val"><%= totalOrders %></div>
                <div class="status-lbl">All Orders</div>
            </div>
            <div class="status-card pending">
                <div class="status-icon">⏳</div>
                <div class="status-val gold"><%= pendingOrders %></div>
                <div class="status-lbl">Pending</div>
            </div>
            <div class="status-card done">
                <div class="status-icon">✅</div>
                <div class="status-val green"><%= deliveredOrders %></div>
                <div class="status-lbl">Delivered</div>
            </div>
            <div class="status-card cancelled">
                <div class="status-icon">❌</div>
                <div class="status-val red"><%= cancelledOrders %></div>
                <div class="status-lbl">Cancelled</div>
            </div>
        </div>

        <%-- BOTTOM ROW --%>
        <div class="bottom-row">

            <%-- Most Visited Pages --%>
            <div class="card">
                <div class="ch">
                    <div class="ch-title">📄 Most Visited Pages</div>
                    <span class="ch-badge"><%= topPages.size() %> pages</span>
                </div>
                <div class="cb">
                    <% if (topPages.isEmpty()) { %>
                        <p class="empty">No page visit data yet</p>
                    <% } else {
                        int mx = Integer.parseInt(topPages.get(0)[2]);
                        for (int i = 0; i < topPages.size(); i++) {
                            String[] pg = topPages.get(i);
                            int c = Integer.parseInt(pg[2]);
                            int p = mx > 0 ? c * 100 / mx : 0;
                            boolean isTop = i == 0;
                    %>
                    <div class="page-row">
                        <div class="page-rank <%= isTop ? "top" : "" %>"><%= i+1 %></div>
                        <div class="page-info">
                            <div class="page-name"><%= pg[0] %></div>
                            <div class="page-url-small"><%= pg[1] %></div>
                            <div class="page-bar-bg">
                                <div class="page-bar-fill" style="width:<%= p %>%"></div>
                            </div>
                        </div>
                        <div class="page-count"><%= c %></div>
                    </div>
                    <% } } %>
                </div>
            </div>

            <%-- Right column: Avg Time Ring + Time Per Page --%>
            <div class="bottom-right-col">

                <%-- AVG TIME RING --%>
                <div class="time-card">
                    <%
                        double maxTime = 120.0;
                        double ringPct = Math.min(avgTime / maxTime, 1.0);
                        int ringDeg    = (int)(ringPct * 360);
                        String ringColor = avgTime >= 60 ? "var(--mint), var(--sage)"
                                         : avgTime >= 30 ? "var(--gold), #e6a020"
                                         : "var(--ember), #c0402a";
                    %>
                    <div class="time-ring" style="background:conic-gradient(<%= ringColor %> 0deg <%= ringDeg %>deg, #eee <%= ringDeg %>deg);">
                        <div class="time-ring-inner">
                            <div class="time-big"><%= String.format("%.0f", avgTime) %></div>
                            <div class="time-unit">seconds</div>
                        </div>
                    </div>
                    <div class="time-title">Avg. Time on Page</div>
                    <div class="time-tip">
                        <% if (avgTime >= 60) { %>
                            🟢 Great engagement! Users spend over a minute per page.
                        <% } else if (avgTime >= 30) { %>
                            🟡 Decent engagement. Aim for 60+ seconds.
                        <% } else if (avgTime > 0) { %>
                            🔴 Low dwell time. Improve page content or layout.
                        <% } else { %>
                            ⚪ No time data recorded yet.
                        <% } %>
                    </div>
                </div>

                <%-- TIME PER PAGE --%>
                <div class="card">
                    <div class="ch"><div class="ch-title">⏱️ Time per Page</div></div>
                    <div class="cb">
                        <% if (timePerPage.isEmpty()) { %>
                            <p class="empty">No time data yet</p>
                        <% } else {
                            int mxT = Integer.parseInt(timePerPage.get(0)[1]);
                            for (String[] tp : timePerPage) {
                                int t = Integer.parseInt(tp[1]);
                                int pct = mxT > 0 ? t * 100 / mxT : 0;
                        %>
                        <div class="time-row">
                            <div class="time-page-name"><%= tp[0] %></div>
                            <div class="time-bar-wrap">
                                <div class="time-bar-bg">
                                    <div class="time-bar-fill" style="width:<%= pct %>%"></div>
                                </div>
                            </div>
                            <div class="time-val-badge"><%= t %>s</div>
                        </div>
                        <% } } %>
                    </div>
                </div>

            </div>
        </div>

    </div><!-- /content -->
</div><!-- /main -->

<script>
function toggleSb() {
    document.getElementById('sidebar').classList.toggle('open');
    document.getElementById('sbOverlay').classList.toggle('show');
}
function closeSb() {
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('sbOverlay').classList.remove('show');
}
</script>
</body>
</html>
