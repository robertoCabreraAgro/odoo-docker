Write-Host "`n==> Deteniendo contenedores..."
docker-compose down

# Write-Host "==> Eliminando volúmenes para entorno limpio ( BORRA TODO)"
# docker volume prune -f

Write-Host "`n==> Construyendo contenedores (puede tardar)..."
docker-compose build

Write-Host "`n==> Levantando servicios..."
docker-compose up -d

Write-Host "`n==> Esperando a que PostgreSQL esté listo..."
$timeout = 60
$startTime = Get-Date
do {
    Start-Sleep -Seconds 3
    $health = docker inspect -f "{{.State.Health.Status}}" postgres_16 2>$null
    $elapsed = (Get-Date) - $startTime
    Write-Host " Esperando PostgreSQL... Estado actual: $health ($($elapsed.Seconds)s)"
}
while ($health -ne "healthy" -and $elapsed.TotalSeconds -lt $timeout)

if ($health -ne "healthy") {
    Write-Error " PostgreSQL no respondió en el tiempo esperado. Abortando..."
    exit 1
}

Write-Host "`n==> Restaurando backup de base de datos y filestore..."

# Descomprimir backup
if (Test-Path "restore_tmp") {
    Remove-Item -Recurse -Force "restore_tmp"
    Write-Host "==> Carpeta temporal eliminada."
}
Expand-Archive -Path "marin182_2025-06-04_22-29-01.zip" -DestinationPath "restore_tmp"

# Restaurar base de datos
if (Test-Path "restore_tmp\dump.sql") {
    docker cp "restore_tmp\dump.sql" postgres_16:/tmp/dump.sql

    docker exec -u root postgres_16 psql -U openpg -d template1 -c "DROP DATABASE IF EXISTS marin182;"
    docker exec -u root postgres_16 psql -U openpg -d template1 -c "CREATE DATABASE marin182 ENCODING 'UTF8' LC_COLLATE 'C' TEMPLATE=template0;"
    docker exec -u root postgres_16 psql -U openpg -d marin182 -f /tmp/dump.sql

    Write-Host " Base de datos restaurada correctamente."
} else {
    Write-Warning " No se encontró dump.sql, omitiendo restauración de base."
}

# Restaurar filestore
$filestorePath = "restore_tmp\filestore"
if (Test-Path $filestorePath) {
    docker exec -u root odoo_18_2_marin mkdir -p /opt/odoo/.data/filestore/marin182
    docker cp "$filestorePath\." odoo_18_2_marin:/opt/odoo/.data/filestore/marin182/
    Write-Host " Filestore restaurado correctamente."
} else {
    Write-Warning " No se encontró carpeta filestore, omitiendo restauración de archivos."
}


Write-Host "`n Restauración completada."

# Opcional: regenerar assets si hubo error de frontend
# Write-Host "`n🧹 Limpiando y regenerando assets (opcional)..."
# docker exec -u root odoo_18_2_marin rm -rf /opt/odoo/.local/share/Odoo/web/assets/*
# docker exec -u root odoo_18_2_marin python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf -d marin182 -u web --stop-after-init
# docker-compose restart odoo_18_2_marin

Write-Host "`n Mostrando logs de Odoo..."
docker-compose logs -f odoo
