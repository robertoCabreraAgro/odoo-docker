FROM python:3.11

# Variables
ENV LANG C.UTF-8
ENV ODOO_HOME=/opt/odoo
ENV ODOO_VERSION=18.2

# Crea usuario odoo
RUN useradd -m -d $ODOO_HOME -U -r -s /bin/bash odoo

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y \
    git gcc g++ wget node-less libldap2-dev libsasl2-dev \
    libpq-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev \
    libssl-dev libffi-dev libjpeg-dev liblcms2-dev libblas-dev libatlas-base-dev \
    postgresql-client \
    && apt-get clean


# Clona Odoo core (personalizado)
RUN git clone --depth 1 -b saas-18.2-marin https://github.com/robertoCabreraAgro/odoo.git /opt/odoo/odoo

# Addons custom
RUN git clone -b saas-18.2 --depth 1 https://github.com/robertoCabreraAgro/addons_custom.git /opt/odoo/addons_custom

# ZZAddons enterprise
RUN git clone -b saas-18.2-marin --depth 1 https://github.com/robertoCabreraAgro/enterprise.git /opt/odoo/enterprise

# ZZThemes (si lo manejas por separado ahora)
RUN git clone -b 18.0 --depth 1 https://github.com/odoo/design-themes.git /opt/odoo/design-themes

# Copia el archivo de configuración y requirements
COPY ./odoo.conf /etc/odoo/odoo.conf
COPY ./requirements.txt /tmp/requirements.txt

RUN pip3 install -r https://github.com/odoo/odoo/raw/saas-18.2/requirements.txt 

# Instala dependencias Python
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN mkdir -p /opt/odoo/.data && chown -R odoo:odoo /opt/odoo/.data

RUN mkdir -p /opt/odoo/sessions && chown -R odoo:odoo /opt/odoo/sessions

# Usuario final
USER odoo
WORKDIR $ODOO_HOME/odoo

CMD ["python", "odoo-bin", "-c", "/etc/odoo/odoo.conf"]
