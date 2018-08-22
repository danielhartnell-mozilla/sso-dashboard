FROM centos:7

EXPOSE 8000
WORKDIR /app/dashboard

RUN yum install -y epel-release
RUN yum install -y python34 python34-devel python34-pip curl gcc libffi-devel openssl-devel curl-devel git rubygem-sass
RUN curl -Lo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.0.2/dumb-init_1.0.2_amd64
RUN chmod 0775 /usr/bin/dumb-init
RUN pip3 install credstash
COPY . /app
RUN pip3 install -r /app/requirements.txt
RUN pip3 install -r /app/ansible/requirements.txt
RUN pip3 install git+git://github.com/mozilla-iam/pyoidc.git@hotfix_unicode#egg=pyoidc
RUN pip3 install --upgrade pyOpenSSL==17.3.0
RUN pip3 install --upgrade cryptography==2.0
COPY ./ansible/roles/dashboard/files/nginx/start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh

CMD ["/usr/bin/dumb-init", "/usr/bin/start.sh"]
