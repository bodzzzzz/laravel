<?php

use Illuminate\Support\Facades\Route;

// Default welcome route
Route::get('/', function () {
    return view('welcome');
});

// Health check route (matches your bootstrap config)
Route::get('/up', function () {
    return 'OK';
});
