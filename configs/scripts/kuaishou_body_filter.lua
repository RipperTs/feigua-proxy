ngx.arg[1] = ngx.arg[1]:gsub("document.domain = 'feigua.cn';", '')
ngx.arg[1] = ngx.arg[1]:gsub('</head>', [[
    <meta name="referrer" content="no-referrer">
    <style>
        .logo {
            display: none;
        }
        .new-dashboard-right section:nth-child(1),
        .new-dashboard-right section:nth-child(2),
        .bottom-nav {
            display: none;
        }
        .userinfo {
            display: none;
        }
	.promotion-12-small {
		display: none !important;
	}
    </style>
    <script>
        ckflag = 1;
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelector('.userinfo').remove();
            document.querySelector('.s-nav ul>li:nth-child(10)').remove();
            document.querySelector('.s-nav ul>li:nth-child(10)').remove();
        });
    </script>
    </head>
]])
