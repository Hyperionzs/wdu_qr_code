use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PermissionController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // User management routes (admin only)
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'store']);
    Route::put('/users/{user}', [UserController::class, 'update']);
    Route::delete('/users/{user}', [UserController::class, 'destroy']);
    
    // User profile and role
    Route::get('/user/role', [UserController::class, 'checkRole']);
    Route::get('/user/profile', [UserController::class, 'profile']);
    
    // Logout
    Route::post('/logout', [AuthController::class, 'logout']);

    // Permission summary
    Route::get('/permissions/summary', [PermissionController::class, 'getPermissionSummary']);
}); 