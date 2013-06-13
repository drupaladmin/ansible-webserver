server {
    listen                      80;
    server_name                 dev.maks-portal.ru;
    server_name_in_redirect     off;
# initialize variable
    set $mobi "";
    set $mobile "";

#Setting cookie for mobiles user agents
    if ($http_user_agent ~* "android|blackberry|iphone|ipad|ipod|iemobile|opera mobile|palmos|webos|googlebot-mobile") {
      set $mobile "mt_device=mobile";
    }
    add_header Set-Cookie $mobile;


    #rewriting to mobile version
    if ($http_cookie ~* "mt_device=(mobile)") {
	set $mobi P;
    }
    if ($host != m.maks-portal.ru) {
	set $mobi "${mobi}C";
    }
    if ($mobi = PC) {
	rewrite ^(.*)$ http://m.maks-portal.ru$1 permanent;
        break;
    }


    fastcgi_keep_conn off;
    fastcgi_intercept_errors on;
    proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
    fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;

    include /etc/nginx/rewrites;
    access_log /home/webmaster/domains/logs/maks-portal-nginx_access.log main;
    error_log /home/webmaster/domains/logs/maks-portal-nginx_error.log warn;
    fastcgi_read_timeout 600s;
    root                        /home/webmaster/domains/maks-portal.ru;

    charset utf-8;

    client_body_buffer_size     32m;
    client_max_body_size        32m;
    proxy_buffering             on;
    proxy_buffer_size           128k;
    proxy_buffers               8 256k;
    proxy_busy_buffers_size     512k;

    fastcgi_connect_timeout 600s;
    fastcgi_send_timeout 600s;
    #fastcgi_read_timeout 600s;
    fastcgi_buffer_size 256k;
    fastcgi_buffers 256 16k;
    fastcgi_busy_buffers_size 256k;
    fastcgi_temp_file_write_size 256k;
    fastcgi_max_temp_file_size 0;


    # serve imagecache files directly or redirect to drupal if they do not exist
    location ^~ /sites/default/files/imagecache/ {
    	access_log off;
        expires 30d;
        try_files $uri @rewrite;
    }

    # serve static files directly
    location ~* ^.+\.(gz|jpg|jpeg|gif|css|png|js|ico|html|swf|flv)$ {
    	access_log        off;
        expires           30d;
    }

    location ~* \.(engine|inc|info|install|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)$|^(\..*|Entries.*|Repository|Root|Tag|Template)$|\.php_ {
        deny all;
    }


    location /status {
	fastcgi_pass   php5-fpm;
	include fastcgi_params;
	fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
	allow 195.211.111.138;
	allow 77.106.212.106;
	allow 46.29.12.27;
	allow 37.147.37.44;
	allow 193.242.149.77;
	deny all;
    }

    location /nginx_status {
	stub_status on;
	access_log   off;
	allow 195.211.111.138;
	allow 77.106.212.106;
	allow 46.29.12.27;
	allow 37.147.37.44;
	allow 193.242.149.77;
	deny all;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

#PHP-FPM;
     location ~ \.php$ {
	try_files $uri @cache;
        fastcgi_pass   php5-fpm;
	fastcgi_param  SCRIPT_FILENAME  /home/webmaster/domains/maks-portal.ru$fastcgi_script_name;
	fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
	fastcgi_param  REMOTE_ADDR        $remote_addr;
	fastcgi_param  REMOTE_PORT        $remote_port;
	fastcgi_param  SERVER_ADDR        $server_addr;
	fastcgi_param  SERVER_PORT        $server_port;
	fastcgi_param  SERVER_NAME        $server_name;
	fastcgi_param  REQUEST_METHOD     $request_method;
	fastcgi_param  CONTENT_TYPE       $content_type;
	fastcgi_param  CONTENT_LENGTH     $content_length;
	fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
	include /etc/nginx/fastcgi_params;
}
    
    location ~ /503\.(jpg|html) {
    }

    location / {
	rewrite ^/ru/(.*)$ /$1 permanent;
	rewrite ^/fr/(.*)$ /$1 permanent;
	rewrite ^/eng/(.*)$ /$1 permanent;
	rewrite ^/de/(.*)$ /$1 permanent;
        try_files $uri @cache;
    }

    location @cache {
        if ($query_string ~ ".+") {
            return 405;
        }
        if ($cookie_DRUPAL_UID) {
            return 405;
        }
        if ($request_method !~ ^(GET|HEAD)$) {
            return 405;
        }
        error_page 405 = @rewrite;

        add_header Expires "Sun, 19 Nov 1978 05:00:00 GMT";
        add_header Cache-Control "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";

        try_files /cache/normal/$host/${uri}_.html /cache/perm/$host/${uri}_.css /cache/perm/$host/${uri}_.js /cache/$host/0$uri.html /cache/$host/0${uri}/index.html @rewrite;
    }

    location @rewrite {
    	rewrite ^/(.*)$ /index.php?q=$1 last;
    }

    location /banners {
	index index.php;
    }


    error_page   500 503  /503.html;
    error_page 502 =301 @cache;

}

