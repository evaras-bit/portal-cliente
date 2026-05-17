FROM nginx:alpine

# Copiar archivos estáticos al directorio de Nginx
COPY public/ /usr/share/nginx/html/

# Configuración opcional de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
