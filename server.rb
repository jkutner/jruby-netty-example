require "java"
require 'jbundler'

java_import "io.netty.channel.SimpleChannelInboundHandler"
java_import "io.netty.channel.ChannelInitializer"

java_import "io.netty.channel.nio.NioEventLoopGroup"
java_import "io.netty.bootstrap.ServerBootstrap"
java_import "io.netty.channel.socket.nio.NioServerSocketChannel"
java_import "io.netty.channel.ChannelOption"
java_import "io.netty.buffer.PooledByteBufAllocator"
java_import "io.netty.handler.codec.http.HttpRequestDecoder"
java_import "io.netty.handler.codec.http.HttpResponseEncoder"

java_import "io.netty.handler.codec.http.HttpRequest"
java_import "io.netty.handler.codec.http.DefaultFullHttpResponse"
java_import "io.netty.handler.codec.http.HttpVersion"
java_import "io.netty.handler.codec.http.HttpResponseStatus"
java_import "io.netty.handler.codec.http.HttpHeaders"
java_import "io.netty.buffer.Unpooled"

class MySuperHttpHandler < SimpleChannelInboundHandler

  def channelReadComplete(ctx)
    ctx.flush
  end

  def channelRead0(ctx, req)
    if req.is_a? HttpRequest

      reqUrl = req.getUri

      puts "Request: #{reqUrl}"

      if HttpHeaders.is100ContinueExpected(req)
        ctx.write(DefaultFullHttpResponse.new(
          HttpVersion::HTTP_1_1,
          HttpResponseStatus::CONTINUE))
      end

      content = "Hello".to_java.getBytes

      keepAlive = HttpHeaders.isKeepAlive(req);
      response = DefaultFullHttpResponse.new(
        HttpVersion::HTTP_1_1,
        HttpResponseStatus::OK,
        Unpooled.wrappedBuffer(content));

      response.headers.set(HttpHeaders::Names::CONTENT_TYPE, "text/plain");
      response.headers.set(HttpHeaders::Names::CONTENT_LENGTH, response.content.readableBytes)

      if keepAlive
        response.headers().set(HttpHeaders::Names::CONNECTION, HttpHeaders::Values::KEEP_ALIVE)
        ctx.write(response)
      else
        ctx.write(response).addListener(ChannelFutureListener::CLOSE);
      end
    end
  rescue Exception => e
    puts e
    puts e.backtrace
    raise e
  end

  def exceptionCaught(ctx, cause)
      ctx.close
  end
end

class MyChildHandler < ChannelInitializer
  def initChannel(ch)
    p = ch.pipeline
    p.addLast(HttpRequestDecoder.new)
    p.addLast(HttpResponseEncoder.new)
    p.addLast(MySuperHttpHandler.new)
  end
end

bossGroup = NioEventLoopGroup.new(1)
workerGroup = NioEventLoopGroup.new

begin
  bootstrap = ServerBootstrap.new
  bootstrap.group(bossGroup, workerGroup)
    .channel(NioServerSocketChannel.java_class)
    .option(ChannelOption::SO_BACKLOG, java.lang.Integer.new("200"))
    .childOption(ChannelOption::ALLOCATOR, PooledByteBufAllocator::DEFAULT)
    .childHandler(MyChildHandler.new)


  port = ENV['PORT'] || 8080
  puts "Starting Netty server on port #{port}"
  future = bootstrap.bind(port.to_i).sync
  future.channel.closeFuture.sync
ensure
  bossGroup.shutdownGracefully
  workerGroup.shutdownGracefully

  bossGroup.terminationFuture.sync
  workerGroup.terminationFuture.sync
end
