namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    public function recap(Request $request)
    {
        try {
            $month = $request->query('month', Carbon::now()->format('m'));
            $year = $request->query('year', Carbon::now()->format('Y'));
            $userId = $request->query('user_id');

            // Base query
            $query = User::query()
                ->when(!$request->user()->isAdmin(), function ($query) use ($request) {
                    // If not admin, only show own data
                    $query->where('id', $request->user()->id);
                })
                ->when($userId && $userId !== 'all' && $request->user()->isAdmin(), function ($query) use ($userId) {
                    // If admin and specific user selected
                    $query->where('id', $userId);
                })
                ->where('status', 'active')
                ->with(['attendances' => function ($query) use ($month, $year) {
                    $query->whereYear('date', $year)
                          ->whereMonth('date', $month);
                }]);

            $users = $query->get();

            $recapData = $users->map(function ($user) {
                $attendances = $user->attendances;
                
                return [
                    'user_id' => $user->id,
                    'user_name' => $user->name,
                    'present_count' => $attendances->where('status', 'present')->count(),
                    'late_count' => $attendances->where('status', 'late')->count(),
                    'absent_count' => $attendances->where('status', 'absent')->count(),
                    'permission_count' => $attendances->where('status', 'permission')->count(),
                    'leave_count' => $attendances->where('status', 'leave')->count(),
                    'overtime_count' => $attendances->where('status', 'overtime')->count(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $recapData
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching attendance data: ' . $e->getMessage()
            ], 500);
        }
    }
} 