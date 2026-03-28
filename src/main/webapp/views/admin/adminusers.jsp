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

    <!-- ⚠️ NO UI CHANGES BELOW -->
    <style>
        :root {
            --forest:#0d2318; --pine:#153a25; --leaf:#1e5c38; --sage:#2d8653; --mint:#4eca7f;
            --frost:#d4f5e4; --cream:#f7f3ed; --bg:#f2f4f3; --ember:#e8603c; --gold:#f0a843;
            --sky:#3a7bd5; --ink:#0a0f0c; --mist:#8ba898; --border:#e4e8e5; --card:#ffffff;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Instrument Sans',sans-serif; background:var(--bg); color:var(--ink); min-height:100vh; }

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
        .sidebar-footer { padding:1rem; border-top:1px solid rgba(255,255,255,0.07); }

        .main { margin-left:240px; min-height:100vh; }
        .topbar { background:var(--card); border-bottom:1px solid var(--border); padding:0.9rem 2rem; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:100; }
        .page-content { padding:2rem; }

        .stats-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:1rem; margin-bottom:1.5rem; }

        .search-wrap { position:relative; margin-bottom:1.2rem; }

        .sc { background:var(--card); border-radius:16px; border:1px solid var(--border); overflow:hidden; }
    </style>
</head>

<body>

<!-- SIDEBAR -->
<aside class="sidebar">
    <div class="sidebar-logo">
        <div class="logo-mark">🌿</div>
        <div class="logo-txt">Green<span>Cart</span> <span class="admin-pill">Admin</span></div>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section-label">Overview</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp" class="nav-item">📊 Dashboard</a>

        <div class="nav-section-label">Catalog</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminhome.jsp#products-section" class="nav-item">📦 Products</a>

        <div class="nav-section-label">Operations</div>
        <a href="<%=request.getContextPath()%>/views/admin/adminorders.jsp" class="nav-item">🧾 Orders</a>
        <a href="<%=request.getContextPath()%>/views/admin/adminusers.jsp" class="nav-item active">👥 Customers</a>
    </nav>

    <div class="sidebar-footer">
        <a href="<%=request.getContextPath()%>/adminLogout" class="btn-logout">Sign Out</a>
    </div>
</aside>

<div class="main">
    <div class="topbar">
        <div class="topbar-title">👥 Customers & Users</div>
        <a href="<%=request.getContextPath()%>/views/home.jsp" class="btn-view-store" target="_blank">🌐 View Store</a>
    </div>

    <div class="page-content">
        <!-- TABLE -->
        <div class="sc">
            <div class="sc-head">
                <div class="sc-title">All Registered Users</div>
            </div>

            <table class="gc-table">
                <tbody>
                <%
                    while(usrRs.next()) {
                %>
                <tr>
                    <td><%= usrRs.getString("name") %></td>
                </tr>
                <%
                    }
                    usrRs.close(); usrPs.close(); conn.close();
                %>
                </tbody>
            </table>

        </div>
    </div>
</div>

</body>
</html>