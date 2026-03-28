<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String error = (String) request.getAttribute("error");
    // Redirect if already logged in
    String admin = (String) session.getAttribute("admin");
    if (admin != null) {
        response.sendRedirect(request.getContextPath() + "/views/admin/adminhome.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login — GreenCart Control Center</title>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=Instrument+Sans:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --forest:   #0d2318;
            --pine:     #153a25;
            --leaf:     #1e5c38;
            --sage:     #2d8653;
            --mint:     #4eca7f;
            --frost:    #d4f5e4;
            --cream:    #f7f3ed;
            --ember:    #e8603c;
            --gold:     #f0a843;
            --ink:      #0a0f0c;
            --mist:     #8ba898;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Instrument Sans', sans-serif;
            min-height: 100vh;
            background: var(--forest);
            display: grid;
            grid-template-columns: 1fr 1fr;
            overflow: hidden;
        }

        /* LEFT PANEL */
        .left-panel {
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 3rem;
            background: var(--pine);
            overflow: hidden;
        }

        .left-panel::before {
            content: '';
            position: absolute;
            width: 500px; height: 500px;
            background: radial-gradient(circle, rgba(78,202,127,0.12), transparent 65%);
            top: -100px; left: -100px;
            pointer-events: none;
        }
        .left-panel::after {
            content: '';
            position: absolute;
            width: 400px; height: 400px;
            background: radial-gradient(circle, rgba(78,202,127,0.08), transparent 65%);
            bottom: -50px; right: -80px;
            pointer-events: none;
        }

        .panel-logo {
            display: flex;
            align-items: center;
            gap: 0.8rem;
            z-index: 1;
        }
        .logo-mark {
            width: 42px; height: 42px;
            background: linear-gradient(135deg, var(--mint), var(--sage));
            border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.3rem;
            box-shadow: 0 4px 20px rgba(78,202,127,0.35);
        }
        .logo-text {
            font-family: 'Syne', sans-serif;
            font-weight: 800;
            font-size: 1.4rem;
            color: #fff;
            letter-spacing: -0.5px;
        }
        .logo-text span { color: var(--mint); }

        .panel-hero {
            z-index: 1;
        }
        .panel-hero h2 {
            font-family: 'Syne', sans-serif;
            font-size: 3.2rem;
            font-weight: 800;
            color: #fff;
            line-height: 1.1;
            letter-spacing: -1.5px;
            margin-bottom: 1rem;
        }
        .panel-hero h2 em {
            font-style: normal;
            color: var(--mint);
        }
        .panel-hero p {
            color: var(--mist);
            font-size: 0.95rem;
            line-height: 1.7;
            max-width: 320px;
        }

        .stats-row {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 1rem;
            z-index: 1;
        }
        .mini-stat {
            background: rgba(255,255,255,0.06);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 14px;
            padding: 1rem;
            backdrop-filter: blur(10px);
        }
        .mini-stat .num {
            font-family: 'Syne', sans-serif;
            font-size: 1.6rem;
            font-weight: 800;
            color: var(--mint);
        }
        .mini-stat .lbl {
            font-size: 0.72rem;
            color: var(--mist);
            font-weight: 500;
            margin-top: 2px;
            letter-spacing: 0.3px;
        }

        /* RIGHT PANEL */
        .right-panel {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 3rem;
            background: var(--cream);
        }

        .login-card {
            width: 100%;
            max-width: 400px;
            animation: slideIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateX(24px); }
            to   { opacity: 1; transform: translateX(0); }
        }

        .card-eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            background: var(--frost);
            color: var(--leaf);
            font-size: 0.72rem;
            font-weight: 600;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            padding: 0.35rem 0.9rem;
            border-radius: 50px;
            margin-bottom: 1.5rem;
        }
        .card-eyebrow::before {
            content: '';
            width: 6px; height: 6px;
            background: var(--sage);
            border-radius: 50%;
        }

        .card-title {
            font-family: 'Syne', sans-serif;
            font-size: 2.2rem;
            font-weight: 800;
            color: var(--ink);
            letter-spacing: -1px;
            line-height: 1.1;
            margin-bottom: 0.4rem;
        }
        .card-sub {
            color: var(--mist);
            font-size: 0.9rem;
            margin-bottom: 2.5rem;
        }

        .alert-err {
            background: #fff0ed;
            border: 1.5px solid #ffc4b4;
            color: var(--ember);
            border-radius: 12px;
            padding: 0.8rem 1rem;
            font-size: 0.85rem;
            font-weight: 500;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .field-group {
            margin-bottom: 1.3rem;
        }
        .field-label {
            display: block;
            font-size: 0.8rem;
            font-weight: 600;
            color: var(--ink);
            margin-bottom: 0.45rem;
            letter-spacing: 0.2px;
        }
        .field-wrap {
            position: relative;
        }
        .field-icon {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            width: 18px;
            color: var(--mist);
            pointer-events: none;
        }
        .field-input {
            width: 100%;
            background: #fff;
            border: 1.5px solid #e2ddd8;
            border-radius: 12px;
            padding: 0.8rem 1rem 0.8rem 2.8rem;
            font-size: 0.92rem;
            font-family: 'Instrument Sans', sans-serif;
            color: var(--ink);
            transition: all 0.2s;
            outline: none;
        }
        .field-input:focus {
            border-color: var(--sage);
            box-shadow: 0 0 0 3px rgba(45,134,83,0.12);
            background: #fff;
        }
        .field-input::placeholder { color: #bbb5ae; }

        .btn-signin {
            width: 100%;
            background: var(--forest);
            color: #fff;
            border: none;
            border-radius: 12px;
            padding: 0.9rem;
            font-size: 0.95rem;
            font-weight: 600;
            font-family: 'Instrument Sans', sans-serif;
            cursor: pointer;
            transition: all 0.25s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            margin-top: 0.5rem;
            letter-spacing: 0.2px;
        }
        .btn-signin:hover {
            background: var(--leaf);
            transform: translateY(-2px);
            box-shadow: 0 12px 32px rgba(13,35,24,0.3);
        }
        .btn-signin .arrow {
            transition: transform 0.2s;
        }
        .btn-signin:hover .arrow { transform: translateX(4px); }

        .divider {
            display: flex; align-items: center; gap: 0.8rem;
            margin: 1.8rem 0 1.2rem;
        }
        .divider hr { flex: 1; border: none; border-top: 1.5px solid #e8e3dd; }
        .divider span { font-size: 0.75rem; color: var(--mist); }

        .back-link {
            text-align: center;
            font-size: 0.83rem;
            color: var(--mist);
        }
        .back-link a {
            color: var(--leaf);
            font-weight: 600;
            text-decoration: none;
            transition: color 0.2s;
        }
        .back-link a:hover { color: var(--sage); }

        @media (max-width: 768px) {
            body { grid-template-columns: 1fr; }
            .left-panel { display: none; }
            .right-panel { padding: 2rem 1.5rem; }
        }
    </style>
</head>
<body>

<!-- LEFT PANEL -->
<div class="left-panel">
    <div class="panel-logo">
        <div class="logo-mark">🌿</div>
        <div class="logo-text">Green<span>Cart</span></div>
    </div>

    <div class="panel-hero">
        <h2>Your store,<br>fully <em>in control</em>.</h2>
        <p>Manage products, track orders, oversee customers — all from one powerful, clean dashboard.</p>
    </div>

    <div class="stats-row">
        <div class="mini-stat">
            <div class="num">100%</div>
            <div class="lbl">Uptime</div>
        </div>
        <div class="mini-stat">
            <div class="num">∞</div>
            <div class="lbl">Products</div>
        </div>
        <div class="mini-stat">
            <div class="num">24/7</div>
            <div class="lbl">Control</div>
        </div>
    </div>
</div>

<!-- RIGHT PANEL -->
<div class="right-panel">
    <div class="login-card">

        <div class="card-eyebrow">Admin Access</div>

        <h1 class="card-title">Welcome<br>back.</h1>
        <p class="card-sub">Sign in to your control center</p>

        <% if (error != null) { %>
        <div class="alert-err">
            <svg width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/></svg>
            <%= error %>
        </div>
        <% } %>

        <form action="<%=request.getContextPath()%>/adminLogin" method="post">

            <div class="field-group">
                <label class="field-label">Username</label>
                <div class="field-wrap">
                    <svg class="field-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    <input type="text" name="adminName" class="field-input" placeholder="admin@greencart" required autocomplete="username">
                </div>
            </div>

            <div class="field-group">
                <label class="field-label">Password</label>
                <div class="field-wrap">
                    <svg class="field-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                    <input type="password" name="adminPass" class="field-input" placeholder="••••••••" required autocomplete="current-password">
                </div>
            </div>

            <button type="submit" class="btn-signin">
                Sign in to Dashboard
                <svg class="arrow" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6"/></svg>
            </button>
        </form>

        <div class="divider">
            <hr><span>Not an admin?</span><hr>
        </div>

        <div class="back-link">
            <a href="<%=request.getContextPath()%>/views/home.jsp">← Back to GreenCart Store</a>
        </div>
    </div>
</div>

</body>
</html>
