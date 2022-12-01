FROM httpd:latest

ENV htdocs /usr/local/apache2/htdocs/

ADD ./assets/ $htdocs/assets
ADD ./error/ $htdocs/error
ADD ./images/ $htdocs/images

COPY ./index.html /usr/local/apache2/htdocs/