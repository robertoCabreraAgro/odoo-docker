Write-Host "==> Deteniendo contenedores..."
docker-compose down

#Write-Host "==> Eliminar volúmenes si lo deseas completamente limpio"
#docker volume prune -f

Write-Host "==> Construyendo contenedores..."
docker-compose build --no-cache
#docker-compose build

Write-Host "==> Levantando servicios..."
docker-compose up -d

#Write-Host "==> Inicializando base de datos Odoo..."
#docker exec odoo_18_2_marin python odoo-bin -c /etc/odoo/odoo.conf -d odoo -i base --without-demo=True --stop-after-init

Write-Host "==> Mostrando logs..."
docker-compose logs -f
