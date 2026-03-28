// ── Green Cart User Behaviour Tracker ────────────────────────────────
// Add this script to every user-facing JSP page

(function () {
    var TRACK_URL  = (typeof window.TRACK_URL !== 'undefined')
                     ? window.TRACK_URL
                     : '/track'; // relative URL — works on any domain

    var sessionStart = Date.now();
    var pageStart    = Date.now();

    // ── Detect device type ──────────────────────────────────────────
    function getDeviceType() {
        var ua = navigator.userAgent;
        if (/Mobi|Android|iPhone|iPad/i.test(ua)) return 'Mobile';
        if (/Tablet|iPad/i.test(ua)) return 'Tablet';
        return 'Desktop';
    }

    // ── Send data to TrackingServlet ────────────────────────────────
    function send(params) {
        var form = new FormData();
        for (var key in params) form.append(key, params[key]);
        navigator.sendBeacon
            ? navigator.sendBeacon(TRACK_URL, form)
            : fetch(TRACK_URL, { method: 'POST', body: form });
    }

    // ── Session Start ───────────────────────────────────────────────
    send({
        action:     'session_start',
        deviceType: getDeviceType(),
        pageUrl:    window.location.pathname
    });

    // ── Page Visit Event ────────────────────────────────────────────
    send({
        action:    'event',
        eventType: 'page_visit',
        eventData: document.title,
        pageUrl:   window.location.pathname,
        timeOnPage: 0
    });

    // ── Track time on page & session end ───────────────────────────
    window.addEventListener('beforeunload', function () {
        var timeOnPage = Math.round((Date.now() - pageStart) / 1000);
        var totalTime  = Math.round((Date.now() - sessionStart) / 1000);

        send({
            action:     'event',
            eventType:  'time_on_page',
            eventData:  document.title,
            pageUrl:    window.location.pathname,
            timeOnPage: timeOnPage
        });

        send({
            action:      'session_end',
            timeOnPage:  totalTime,
            pageUrl:     window.location.pathname
        });
    });

    // ── Product Click Tracking ──────────────────────────────────────
    document.addEventListener('click', function (e) {
        var card = e.target.closest('.product-card');
        if (card) {
            var name = card.querySelector('.product-name');
            if (name) {
                send({
                    action:    'event',
                    eventType: 'product_click',
                    eventData: name.textContent.trim(),
                    pageUrl:   window.location.pathname,
                    timeOnPage: Math.round((Date.now() - pageStart) / 1000)
                });
            }
        }
    });

    // ── Add to Cart / Remove Tracking ──────────────────────────────
    // Called from updateCart() in home.jsp
    window.trackCartEvent = function (action, productName) {
        send({
            action:    'event',
            eventType: action === 'increase' ? 'add_to_cart' : 'remove_from_cart',
            eventData: productName,
            pageUrl:   window.location.pathname,
            timeOnPage: Math.round((Date.now() - pageStart) / 1000)
        });
    };

    // ── Order Placed Tracking ───────────────────────────────────────
    window.trackOrderPlaced = function (orderId, total) {
        send({
            action:    'event',
            eventType: 'order_placed',
            eventData: 'Order: ' + orderId + ' | Total: ₹' + total,
            pageUrl:   window.location.pathname,
            timeOnPage: Math.round((Date.now() - pageStart) / 1000)
        });
    };

})();