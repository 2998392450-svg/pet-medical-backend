package com.petclinic.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web 配置类
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * 配置静态资源处理
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 配置静态资源访问路径（如上传的文件等）
        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/");
        
        // 配置上传文件的访问路径
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:uploads/");
    }

    /**
     * 配置拦截器（可用于 JWT 验证等）
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 暂时不添加拦截器，所有接口都开放访问
        // 如果需要 JWT 验证，可以在此添加拦截器
        // registry.addInterceptor(new JwtInterceptor())
        //         .addPathPatterns("/api/**")
        //         .excludePathPatterns("/api/login", "/api/register");
    }
}