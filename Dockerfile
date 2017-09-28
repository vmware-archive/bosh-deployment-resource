FROM alpine:edge AS resource
RUN apk add --update bash openssl ca-certificates tar file ruby ruby-json ruby-nokogiri
ADD . /tmp/resource-gem
RUN cd /tmp/resource-gem && \
    gem build *.gemspec && gem install *.gem --no-document && \
    rm -r /tmp/resource-gem && \
    mkdir -p /opt/resource && \
    ln -s $(which bdr_check) /opt/resource/check && \
    ln -s $(which bdr_in) /opt/resource/in && \
    ln -s $(which bdr_out) /opt/resource/out

FROM resource AS tests
RUN apk add --update ruby-bundler
ADD . /resource
WORKDIR /resource
RUN bundle install
RUN bundle exec rspec

FROM resource
