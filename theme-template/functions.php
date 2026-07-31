<?php
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
    $theme_version = wp_get_theme()->get( 'Version' );

    $css_file = WP_DEBUG
        ? '/assets/css/style.css'
        : '/assets/css/style.min.css';

    $css_path = get_stylesheet_directory() . $css_file;

    if ( file_exists( $css_path ) ) {
        wp_enqueue_style(
            'starter-style',
            get_stylesheet_directory_uri() . $css_file,
            array(),
            $theme_version . '.' . filemtime( $css_path )
        );
    }

    $js_path = get_stylesheet_directory() . '/assets/js/main.js';

    if ( file_exists( $js_path ) ) {
        wp_enqueue_script(
            'starter-main',
            get_stylesheet_directory_uri() . '/assets/js/main.js',
            array(),
            $theme_version,
            true
        );
    }
}
add_action( 'wp_enqueue_scripts', 'starter_theme_scripts' );