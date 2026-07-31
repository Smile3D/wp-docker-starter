const gulp = require('gulp');
const sass = require('gulp-sass')(require('sass'));
const postcss = require('gulp-postcss');
const autoprefixer = require('autoprefixer');
const sourcemaps = require('gulp-sourcemaps');
const cleanCSS = require('gulp-clean-css');
const rename = require('gulp-rename');
const browserSync = require('browser-sync').create();

const paths = {
    scssEntry: 'src/scss/style.scss',
    scssWatch: 'src/scss/**/*.scss',
    jsWatch: 'src/js/**/*.js',
    phpWatch: '**/*.php',
    cssDest: 'assets/css',
    jsDest: 'assets/js',
};

function stylesDev() {
    return gulp.src(paths.scssEntry)
        .pipe(sourcemaps.init())
        .pipe(sass({ outputStyle: 'expanded' }).on('error', sass.logError))
        .pipe(postcss([autoprefixer()]))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(paths.cssDest))
        .pipe(browserSync.stream()); // обновляет CSS без перезагрузки страницы
}

function stylesBuild() {
    return gulp.src(paths.scssEntry)
        .pipe(sass({ outputStyle: 'compressed' }).on('error', sass.logError))
        .pipe(postcss([autoprefixer()]))
        .pipe(cleanCSS())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest(paths.cssDest));
}

function scripts() {
    return gulp.src(paths.jsWatch)
        .pipe(gulp.dest(paths.jsDest))
        .pipe(browserSync.stream());
}

// Подключаемся к уже работающему WordPress в Docker (не поднимаем свой сервер)
function serve(done) {
    browserSync.init({
        proxy: 'localhost:8080', // порт из твоего .env (WORDPRESS_PORT)
        open: false,
        notify: false,
    });
    done();
}

function reload(done) {
    browserSync.reload();
    done();
}

function watchFiles() {
    gulp.watch(paths.scssWatch, stylesDev);
    gulp.watch(paths.jsWatch, gulp.series(scripts, reload));
    gulp.watch(paths.phpWatch, reload); // при сохранении любого .php — полная перезагрузка
}

const build = gulp.parallel(stylesBuild, scripts);
const dev = gulp.series(
    gulp.parallel(stylesDev, scripts),
    serve,
    watchFiles
);

exports.styles = stylesDev;
exports.build = build;
exports.watch = dev;
exports.default = dev;