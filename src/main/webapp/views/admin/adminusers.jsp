<%@page import="java.util.*,java.sql.*,com.ecommerce.model.DbConnection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String admin = (String) session.getAttribute("admin");
    if (admin == null) {
        response.sendRedirect(request.getContextPath() + "/views/admin/adminlogin.jsp");
        return;
    }

    Connection conn = DbConnection.getConnection();

    int totalUsers=0, totalCustomers=0;
    PreparedStatement st; ResultSet rs;
    st = conn.prepareStatement("SELECT COUNT(*) FROM register"); rs = st.executeQuery(); if(rs.next()) totalUsers=rs.getInt(1); rs.close(); st.close();
    st = conn.prepareStatement("SELECT COUNT(*) FROM register WHERE role='Customer'"); rs = st.executeQuery(); if(rs.next()) totalCustomers=rs.getInt(1); rs.close(); st.close();

    // Count admins
    int totalAdmins = totalUsers - totalCustomers;

    PreparedStatement usrPs = conn.prepareStatement(
        "SELECT r.*, " +
        "(SELECT COUNT(*) FROM orders o WHERE o.user_id=r.id) as order_count, " +
        "(SELECT COALESCE(SUM(o2.total_amount),0) FROM orders o2 WHERE o2.user_id=r.id AND o2.status='Delivered') as total_spent " +
        "FROM register r ORDER BY r.id DESC");
    ResultSet usrRs = usrPs.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customers — GreenCart Admin</title>
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
        .stats-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:1rem; margin-bottom:1.5rem; }
        .stat-card { background:var(--card); border-radius:14px; padding:1.2rem 1.3rem; border:1px solid var(--border); }
        .stat-value { font-family:'Syne',sans-serif; font-size:1.6rem; font-weight:800; color:var(--ink); }
        .stat-label { font-size:0.75rem; color:var(--mist); font-weight:500; margin-top:0.2rem; }

        /* SEARCH */
        .search-wrap { position:relative; margin-bottom:1.2rem; }
        .search-input { width:100%; padding:0.65rem 1rem 0.65rem 2.5rem; border:1.5px solid var(--border); border-radius:10px; font-size:0.88rem; font-family:'Instrument Sans',sans-serif; background:var(--card); color:var(--ink); transition:border-color 0.2s; }
        .search-input:focus { outline:none; border-color:var(--sage); }
        .search-icon { position:absolute; left:0.85rem; top:50%; transform:translateY(-50%); color:var(--mist); font-size:0.9rem; }

        /* TABLE */
        .sc { background:var(--card); border-radius:16px; border:1px solid var(--border); box-shadow:0 1px 6px rgba(0,0,0,0.04); overflow:hidden; }
        .sc-head { padding:1.1rem 1.5rem; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
        .sc-title { font-family:'Syne',sans-serif; font-size:0.95rem; font-weight:700; color:var(--ink); }
        .sc-count { font-size:0.78rem; color:var(--mist); font-weight:500; }

        .gc-table { width:100%; border-collapse:collapse; }
        .gc-table thead tr { background:#f8faf9; }
        .gc-table th { padding:0.75rem 1rem; font-size:0.7rem; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; color:var(--mist); text-align:left; border-bottom:1px solid var(--border); }
        .gc-table td { padding:0.85rem 1rem; font-size:0.85rem; border-bottom:1px solid #f0f4f2; vertical-align:middle; }
        .gc-table tbody tr:hover { background:#fafffe; }
        .gc-table tbody tr:last-child td { border-bottom:none; }

        .user-avatar { width:34px; height:34px; border-radius:9px; display:flex; align-items:center; justify-content:center; font-size:0.9rem; font-weight:700; color:#fff; flex-shrink:0; }
        .user-name { font-weight:600; color:var(--ink); font-size:0.85rem; }
        .user-email { font-size:0.72rem; color:var(--mist); }
        .badge-id { font-size:0.72rem; font-weight:600; background:#f2f4f3; color:var(--mist); padding:0.18rem 0.5rem; border-radius:6px; font-family:monospace; }
        .price-val { font-weight:700; color:var(--sage); }
        .text-muted-sm { font-size:0.75rem; color:var(--mist); }

        .role-customer { background:#e6f9ef; color:var(--sage); font-size:0.7rem; font-weight:700; padding:0.18rem 0.6rem; border-radius:50px; border:1px solid #b8dfc9; }
        .role-admin    { background:rgba(78,202,127,0.15); color:var(--mint); font-size:0.7rem; font-weight:700; padding:0.18rem 0.6rem; border-radius:50px; border:1px solid rgba(78,202,127,0.3); }

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
            .stats-grid { grid-template-columns: 1fr 1fr; }
            .gc-table th:nth-child(4),
            .gc-table td:nth-child(4),
            .gc-table th:nth-child(5),
            .gc-table td:nth-child(5) { display: none; }
            .gc-table th, .gc-table td { padding: 0.6rem 0.5rem; font-size: 0.78rem; }
        }
        @media (max-width: 480px) {
            .stats-grid { grid-template-columns: 1fr; }
            .gc-table th:nth-child(3),
            .gc-table td:nth-child(3) { display: none; }
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
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp" class="nav-item"><span>📊</span> Dashboard</a>
        <div class="nav-section-label">Catalog</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp#products-section" class="nav-item"><span>📦</span> Products</a>
        <div class="nav-section-label">Operations</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="nav-item"><span>🧾</span> Orders</a>
        <a href="<%=request.getContextPath()%>/views/admin/adminusers.jsp" class="nav-item active"><span>👥</span> Customers</a>
        <a href="<%=request.getContextPath()%>/views/admin/adminanalytics.jsp" class="nav-item"><span>📈</span> Analytics</a>
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
            <div class="topbar-title">👥 Customers & Users</div>
        </div>
        <a href="<%=request.getContextPath()%>/views/user/home.jsp" class="btn-view-store" target="_blank">🌐 View Store</a>
    </div>

    <div class="page-content">

        <!-- STATS -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value"><%= totalUsers %></div>
                <div class="stat-label">Total Users</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:var(--sage)"><%= totalCustomers %></div>
                <div class="stat-label">Customers</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" style="color:var(--mint)"><%= totalAdmins %></div>
                <div class="stat-label">Admins</div>
            </div>
        </div>

        <!-- SEARCH -->
        <div class="search-wrap">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-input" id="userSearch" placeholder="Search by name or email…" oninput="filterTable()">
        </div>

        <!-- USERS TABLE -->
        <div class="sc">
            <div class="sc-head">
                <div class="sc-title">All Registered Users</div>
                <div class="sc-count" id="rowCount"></div>
            </div>
            <div style="overflow-x:auto">
                <table class="gc-table" id="userTable">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Role</th>
                            <th>Orders</th>
                            <th>Total Spent</th>
                            <th>ID</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        int rowNum = 0;
                        String[] avatarColors = {"#2d8653","#3a7bd5","#e8603c","#9b59b6","#f0a843","#1e5c38"};
                        while(usrRs.next()) {
                            rowNum++;
                            int uid        = usrRs.getInt("id");
                            String uname   = usrRs.getString("name");
                            String uemail  = usrRs.getString("email");
                            String urole   = usrRs.getString("role");
                            int uorders    = usrRs.getInt("order_count");
                            double uspent  = usrRs.getDouble("total_spent");
                            if(uname == null) uname = "—";
                            if(uemail == null) uemail = "—";
                            if(urole == null) urole = "Customer";
                            String avatarColor = avatarColors[uid % avatarColors.length];
                            String initial = uname.length() > 0 ? String.valueOf(uname.charAt(0)).toUpperCase() : "?";
                            String roleBadge = "Admin".equalsIgnoreCase(urole) ? "role-admin" : "role-customer";
                    %>
                    <tr>
                        <td>
                            <div style="display:flex;align-items:center;gap:0.65rem;">
                                <div class="user-avatar" style="background:<%= avatarColor %>"><%= initial %></div>
                                <div>
                                    <div class="user-name"><%= uname %></div>
                                    <div class="user-email"><%= uemail %></div>
                                </div>
                            </div>
                        </td>
                        <td><span class="<%= roleBadge %>"><%= urole %></span></td>
                        <td><span class="text-muted-sm"><%= uorders %> order(s)</span></td>
                        <td><span class="price-val">₹<%= String.format("%,.2f", uspent) %></span></td>
                        <td><span class="badge-id">#<%= uid %></span></td>
                    </tr>
                    <%
                        }
                        usrRs.close(); usrPs.close(); conn.close();
                        if(rowNum == 0) {
                    %>
                    <tr><td colspan="5"><div class="empty-state"><div class="icon">👤</div><p>No users registered yet.</p></div></td></tr>
                    <%  } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</div>

<script>
    function openSidebar()  { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebarOverlay').classList.add('open'); }
    function closeSidebar() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebarOverlay').classList.remove('open'); }

    function filterTable() {
        const q = document.getElementById('userSearch').value.toLowerCase();
        const rows = document.querySelectorAll('#userTable tbody tr');
        let visible = 0;
        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const show = text.includes(q);
            row.style.display = show ? '' : 'none';
            if(show) visible++;
        });
        document.getElementById('rowCount').textContent = visible + ' user(s)';
    }

    // Init count
    window.addEventListener('DOMContentLoaded', () => {
        const rows = document.querySelectorAll('#userTable tbody tr');
        document.getElementById('rowCount').textContent = rows.length + ' user(s)';
    });
</script>
</body>
</html>
