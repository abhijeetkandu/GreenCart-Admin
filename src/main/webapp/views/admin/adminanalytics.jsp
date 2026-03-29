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

    // Avg Time on Page — confirmed working
    ps = conn.prepareStatement(
        "SELECT COALESCE(AVG(time_on_page),0) FROM user_events " +
        "WHERE event_type IN ('time_on_page','time_spent') AND time_on_page > 0");
    rs = ps.executeQuery();
    double avgTime = rs.next() ? rs.getDouble(1) : 0;
    rs.close(); ps.close();

    // Orders — from orders table directly, confirmed working
    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders");
    rs = ps.executeQuery();
    int totalOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    ps = conn.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
    rs = ps.executeQuery();
    int pendingOrders = rs.next() ? rs.getInt(1) : 0;
    rs.close(); ps.close();

    // Top pages — confirmed working
    ps = conn.prepareStatement(
        "SELECT page_url, COUNT(*) as cnt FROM user_events " +
        "WHERE event_type='page_visit' AND page_url IS NOT NULL AND page_url!='' " +
        "GROUP BY page_url ORDER BY cnt DESC LIMIT 6");
    rs = ps.executeQuery();
    List<String[]> topPages = new ArrayList<>();
    while(rs.next()) topPages.add(new String[]{rs.getString("page_url"), String.valueOf(rs.getInt("cnt"))});
    rs.close(); ps.close();

    conn.close();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analytics - GreenCart Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --forest:#0d2318; --sage:#2d8653; --mint:#4eca7f; --frost:#d4f5e4;
            --bg:#f2f4f3; --ember:#e8603c; --sky:#3a7bd5;
            --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        *{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Instrument Sans',sans-serif;background:var(--bg);color:var(--ink);min-height:100vh;}

        /* SIDEBAR */
        .sidebar{width:230px;background:var(--forest);display:flex;flex-direction:column;position:fixed;top:0;bottom:0;left:0;z-index:200;transition:transform 0.3s;}
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
        .sb-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:199;}
        .sb-overlay.show{display:block;}

        /* MAIN */
        .main{margin-left:230px;min-height:100vh;}
        .topbar{background:var(--card);border-bottom:1px solid var(--border);padding:0.85rem 1.8rem;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;}
        .tb-left{display:flex;align-items:center;gap:1rem;}
        .btn-menu{display:none;background:none;border:none;cursor:pointer;padding:0.3rem;border-radius:8px;color:var(--ink);}
        .tb-title{font-family:'Syne',sans-serif;font-size:1.1rem;font-weight:700;}
        .btn-store{display:flex;align-items:center;gap:0.4rem;background:var(--frost);color:#1e5c38;border:1px solid rgba(30,92,56,0.15);border-radius:8px;padding:0.45rem 0.9rem;font-size:0.8rem;font-weight:600;text-decoration:none;transition:all 0.2s;}
        .btn-store:hover{background:#1e5c38;color:#fff;}

        .content{padding:1.6rem;}

        /* STAT CARDS */
        .stats{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem;margin-bottom:1.4rem;}
        .sc{background:var(--card);border-radius:13px;padding:1.2rem 1.3rem;border:1px solid var(--border);display:flex;align-items:center;gap:0.9rem;}
        .si{font-size:1.4rem;width:44px;height:44px;border-radius:11px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
        .si.y{background:#fffbe6;} .si.g{background:#e6f9ef;} .si.o{background:#fff0ec;}
        .sv{font-family:'Syne',sans-serif;font-size:1.5rem;font-weight:800;color:var(--ink);line-height:1;}
        .sl{font-size:0.72rem;color:var(--mist);font-weight:500;margin-top:3px;}

        /* CARDS */
        .card{background:var(--card);border-radius:14px;border:1px solid var(--border);box-shadow:0 1px 4px rgba(0,0,0,0.04);overflow:hidden;margin-bottom:1.2rem;}
        .ch{padding:0.9rem 1.3rem;border-bottom:1px solid var(--border);}
        .ch-title{font-family:'Syne',sans-serif;font-size:0.9rem;font-weight:700;}
        .cb{padding:1.2rem 1.3rem;}
        .g2{display:grid;grid-template-columns:1fr 1fr;gap:1.2rem;margin-bottom:1.2rem;}

        /* BARS */
        .br{margin-bottom:0.85rem;}
        .bl{display:flex;justify-content:space-between;font-size:0.8rem;margin-bottom:4px;font-weight:500;}
        .bl span:last-child{color:var(--mist);}
        .bt{height:7px;background:#f0f0f0;border-radius:50px;overflow:hidden;}
        .bf{height:100%;border-radius:50px;background:linear-gradient(to right,var(--mint),var(--sage));}

        .empty{color:var(--mist);font-size:0.82rem;text-align:center;padding:2rem 0;}

        /* Order summary bits */
        .order-big{font-family:'Syne',sans-serif;font-size:3rem;font-weight:800;color:var(--ink);line-height:1;}
        .order-sub{color:var(--mist);font-size:0.83rem;margin-top:0.3rem;}
        .order-chip{background:var(--frost);border-radius:8px;padding:0.4rem 1.1rem;font-size:0.8rem;color:#1e5c38;font-weight:600;margin-top:0.6rem;display:inline-block;}

        @media(max-width:900px){
            .sidebar{transform:translateX(-100%);}
            .sidebar.open{transform:translateX(0);}
            .main{margin-left:0;}
            .btn-menu{display:flex;}
            .topbar{padding:0.85rem 1rem;}
            .content{padding:1rem;}
            .stats{grid-template-columns:1fr 1fr;}
            .g2{grid-template-columns:1fr;}
            .sv{font-size:1.25rem;}
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
            <div><div class="sb-name"><%= admin %></div><div class="sb-role">Super Admin</div></div>
        </div>
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">🚪 Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div class="tb-left">
            <button class="btn-menu" onclick="toggleSb()">
                <svg width="22" height="22" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
                </svg>
            </button>
            <div class="tb-title">📈 Analytics</div>
        </div>
        <a href="<%=request.getContextPath()%>/views/user/home.jsp" class="btn-store" target="_blank">🌐 View Store</a>
    </div>

    <div class="content">

        <!-- STAT CARDS: only confirmed working data -->
        <div class="stats">
            <div class="sc">
                <div class="si y">⏱️</div>
                <div>
                    <div class="sv"><%= String.format("%.0f", avgTime) %>s</div>
                    <div class="sl">Avg Time on Page</div>
                </div>
            </div>
            <div class="sc">
                <div class="si g">📦</div>
                <div>
                    <div class="sv"><%= totalOrders %></div>
                    <div class="sl">Total Orders</div>
                </div>
            </div>
            <div class="sc">
                <div class="si o">⏳</div>
                <div>
                    <div class="sv" style="color:var(--ember)"><%= pendingOrders %></div>
                    <div class="sl">Pending Orders</div>
                </div>
            </div>
        </div>

        <!-- TWO COLUMN: Top Pages + Order Summary -->
        <div class="g2">
            <div class="card">
                <div class="ch"><div class="ch-title">📄 Most Visited Pages</div></div>
                <div class="cb">
                    <% if(topPages.isEmpty()) { %>
                        <p class="empty">No page visit data yet</p>
                    <% } else {
                        int mx = Integer.parseInt(topPages.get(0)[1]);
                        for(String[] pg : topPages) {
                            int c = Integer.parseInt(pg[1]);
                            int p = mx > 0 ? c * 100 / mx : 0;
                    %>
                    <div class="br">
                        <div class="bl"><span><%= pg[0] %></span><span><%= c %></span></div>
                        <div class="bt"><div class="bf" style="width:<%= p %>%"></div></div>
                    </div>
                    <% }} %>
                </div>
            </div>

            <div class="card">
                <div class="ch"><div class="ch-title">📦 Order Summary</div></div>
                <div class="cb" style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:200px;text-align:center;">
                    <div class="order-big"><%= totalOrders %></div>
                    <div class="order-sub">Total Orders Placed</div>
                    <div class="order-chip">
                        <%= pendingOrders %> Pending &nbsp;|&nbsp; <%= totalOrders - pendingOrders %> Completed
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<script>
function toggleSb(){
    document.getElementById('sidebar').classList.toggle('open');
    document.getElementById('sbOverlay').classList.toggle('show');
}
function closeSb(){
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('sbOverlay').classList.remove('show');
}
</script>
</body>
</html>
