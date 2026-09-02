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

/**
 * ACF Local JSON — инфраструктура пайплайна полей.
 *
 * Группы полей (и другие сущности ACF), сохранённые в админке, пишутся в
 * acf-json/ внутри активной темы и оттуда же подхватываются на новом окружении.
 * Папку acf-json/ и её содержимое держим под контролем версий — это источник
 * правды по структуре ACF-полей проекта, без ручного экспорта/импорта.
 *
 * Конкретные группы полей здесь НЕ регистрируются — только пути save/load.
 *
 * @see https://www.advancedcustomfields.com/resources/local-json/
 */
function starter_theme_set_acf_json_save_point( $save_path ) {
    return get_stylesheet_directory() . '/acf-json';
}
add_filter( 'acf/settings/save_json', 'starter_theme_set_acf_json_save_point' );

function starter_theme_set_acf_json_load_point( $load_paths ) {
    // Убираем дефолтный путь ACF и подставляем единственный — папку acf-json/
    // активной темы, чтобы ACF не сканировал одну и ту же директорию дважды.
    unset( $load_paths[0] );
    $load_paths[] = get_stylesheet_directory() . '/acf-json';

    return $load_paths;
}
add_filter( 'acf/settings/load_json', 'starter_theme_set_acf_json_load_point' );