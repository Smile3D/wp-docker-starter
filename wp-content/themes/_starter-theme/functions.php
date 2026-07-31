<?php
/**
 * Базовые настройки стартер-темы.
 * Дополняй по мере роста стартер-кита.
 */

function starter_theme_setup() {
    add_theme_support( 'title-tag' );
    add_theme_support( 'post-thumbnails' );
    add_theme_support( 'html5', array( 'search-form', 'comment-form', 'gallery', 'caption' ) );

    register_nav_menus( array(
        'primary' => __( 'Основное меню', 'starter-theme' ),
        'footer'  => __( 'Меню в футере', 'starter-theme' ),
    ) );
}
add_action( 'after_setup_theme', 'starter_theme_setup' );

function starter_theme_scripts() {
    wp_enqueue_style( 'starter-style', get_stylesheet_uri(), array(), '1.0' );
}
add_action( 'wp_enqueue_scripts', 'starter_theme_scripts' );
