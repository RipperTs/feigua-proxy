ngx.arg[1] = ngx.arg[1]:gsub("document.domain = 'feigua.cn';", '')
ngx.arg[1] = ngx.arg[1]:gsub('</head>', [[
    <meta name="referrer" content="no-referrer">
    <script src="https://cdn.bootcdn.net/ajax/libs/jquery/3.6.0/jquery.js"></script>
    <style>
        .userinfo {
            display: none;
        }
        .platform-info-box {
            display: none;
        }
        .logo {
            display: none;
        }
        #div_DashBoard_Carousels{
            display: none!important;
        }
        .dashboardBanner{
            display: none!important;
        }
        .v-header .top_search{
            display: none!important;
        }
    </style>
    <script>
        ckflag = 1;
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelector('.userinfo').remove();
            document.querySelector('#__ulNav>li:nth-child(10)').remove();
            document.querySelector('#__ulNav>li:nth-child(10)').remove();
            document.querySelector('#__ulNav>li:nth-child(10)').remove();
            document.querySelector('#__ulNav>li:nth-child(9) li:nth-child(6)').remove()
        });
    </script>
    <script>
            window.setInterval(sendData, 500);
            function sendData(){
                $(".page-404 .btns-unified").attr("href","/");
                $('#useridforcopy').text('110');
                $('.user-info-main').html('<b></b>');
                var tips = $('.page-404 h6').text();
                if(tips.indexOf('访问太频繁') !== -1){
                    $('.page-404 h6').text('访问频繁请稍后访问，或者换个通道在试!');
                }
            }
    </script>
    </head>
]])
