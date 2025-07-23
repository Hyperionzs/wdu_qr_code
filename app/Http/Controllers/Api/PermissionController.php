<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class PermissionController extends Controller
{
    public function getPermissionSummary(Request $request)
    {
        try {
            $userId = Auth::id();
            $now = Carbon::now();
            $month = $request->query('month', $now->month);
            $year = $request->query('year', $now->year);

            Log::info('Fetching permission summary', [
                'user_id' => $userId,
                'year' => $year,
                'month' => $month
            ]);

            $summary = [
                'izin' => Permission::where('user_id', $userId)
                    ->where('type', 'izin')
                    ->whereMonth('tanggal', $month)
                    ->whereYear('tanggal', $year)
                    ->count(),
                'cuti' => Permission::where('user_id', $userId)
                    ->where('type', 'cuti')
                    ->whereMonth('tanggal', $month)
                    ->whereYear('tanggal', $year)
                    ->count(),
                'lembur' => Permission::where('user_id', $userId)
                    ->where('type', 'lembur')
                    ->whereMonth('tanggal', $month)
                    ->whereYear('tanggal', $year)
                    ->count(),
            ];

            Log::info('Permission summary calculated', [
                'summary' => $summary
            ]);

            return response()->json([
                'success' => true,
                'data' => $summary,
                'message' => 'Permission summary retrieved successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Error in getPermissionSummary', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve permission summary',
                'error' => $e->getMessage()
            ], 500);
        }
    }
} 