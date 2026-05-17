package com.example.sqltaskapp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import jakarta.servlet.http.HttpServletRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Controller
public class SqlController {

    private static final DateTimeFormatter HISTORY_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    // DTO for schema column info
    public static class ColumnInfo {
        private final String columnName;
        private final String dataType;
        private final boolean nullable;
        private final String columnDefault;

        public ColumnInfo(String columnName, String dataType, boolean nullable, String columnDefault) {
            this.columnName = columnName;
            this.dataType = dataType;
            this.nullable = nullable;
            this.columnDefault = columnDefault;
        }

        public String getColumnName()   { return columnName; }
        public String getDataType()     { return dataType; }
        public boolean isNullable()     { return nullable; }
        public String getColumnDefault(){ return columnDefault; }
    }

    // DTO for schema table info
    public static class TableInfo {
        private final String tableName;
        private final List<ColumnInfo> columns;

        public TableInfo(String tableName, List<ColumnInfo> columns) {
            this.tableName = tableName;
            this.columns = columns;
        }

        public String getTableName()        { return tableName; }
        public List<ColumnInfo> getColumns(){ return columns; }
    }

    // DTO for task with computed fields
    public static class TaskRow {
        private final Map<String, Object> data;
        private final boolean overdue;
        private final boolean dueSoon;

        public TaskRow(Map<String, Object> data) {
            this.data = data;
            LocalDate today = LocalDate.now();
            Object dueDateObj = data.get("due_date");
            LocalDate dueDate = null;
            if (dueDateObj instanceof java.sql.Date) {
                dueDate = ((java.sql.Date) dueDateObj).toLocalDate();
            } else if (dueDateObj instanceof LocalDate) {
                dueDate = (LocalDate) dueDateObj;
            }
            String status = (String) data.get("status");
            boolean isDone = "DONE".equalsIgnoreCase(status);
            this.overdue  = dueDate != null && dueDate.isBefore(today) && !isDone;
            this.dueSoon  = dueDate != null && !dueDate.isBefore(today)
                            && dueDate.isBefore(today.plusDays(4)) && !isDone;
        }

        public Object get(String key)   { return data.get(key); }
        public Object getId()           { return data.get("id"); }
        public Object getTitle()        { return data.get("title"); }
        public Object getStatus()       { return data.get("status"); }
        public Object getPriority()     { return data.get("priority"); }
        public Object getDue_date()     { return data.get("due_date"); }
        public Object getDescription()  { return data.get("description"); }
        public Object getCreated_at()   { return data.get("created_at"); }
        public boolean isOverdue()      { return overdue; }
        public boolean isDueSoon()      { return dueSoon; }
    }

    // DTO for SQL history entry
    public static class SqlHistoryEntry {
        private final String executedAt;
        private final String query;
        private final String outcome;
        private final double executionTimeMs;

        public SqlHistoryEntry(String executedAt, String query, String outcome, double executionTimeMs) {
            this.executedAt = executedAt;
            this.query = query;
            this.outcome = outcome;
            this.executionTimeMs = executionTimeMs;
        }

        public String getExecutedAt()    { return executedAt; }
        public String getQuery()         { return query; }
        public String getOutcome()       { return outcome; }
        public double getExecutionTimeMs(){ return executionTimeMs; }
        public String getExecutionTime() { return String.format("%.2f ms", executionTimeMs); }
    }

    @Autowired
    private JdbcTemplate jdbcTemplate;

    // ===================== Dashboard =====================

    @GetMapping("/")
    public String dashboard(Model model) {
        // Stats
        Map<String, Object> stats = new HashMap<>();
        stats.put("total",   count("SELECT COUNT(*) FROM tasks"));
        stats.put("doing",   count("SELECT COUNT(*) FROM tasks WHERE status = 'DOING'"));
        stats.put("done",    count("SELECT COUNT(*) FROM tasks WHERE status = 'DONE'"));
        stats.put("overdue", count("SELECT COUNT(*) FROM tasks WHERE due_date < CURRENT_DATE AND status != 'DONE'"));
        model.addAttribute("stats", stats);

        // Chart data
        Map<String, Object> chartData = new HashMap<>();
        List<Map<String, Object>> statusRows = jdbcTemplate.queryForList(
                "SELECT status, COUNT(*) as cnt FROM tasks GROUP BY status ORDER BY status");
        chartData.put("statusLabels", statusRows.stream().map(r -> r.get("status")).collect(Collectors.toList()));
        chartData.put("statusCounts", statusRows.stream().map(r -> r.get("cnt")).collect(Collectors.toList()));

        List<Map<String, Object>> priorityRows = jdbcTemplate.queryForList(
                "SELECT priority, COUNT(*) as cnt FROM tasks GROUP BY priority ORDER BY priority");
        chartData.put("priorityLabels", priorityRows.stream().map(r -> r.get("priority")).collect(Collectors.toList()));
        chartData.put("priorityCounts", priorityRows.stream().map(r -> r.get("cnt")).collect(Collectors.toList()));
        model.addAttribute("chartData", chartData);

        // Recent tasks (up to 10, ordered by due_date)
        List<Map<String, Object>> rawTasks = jdbcTemplate.queryForList(
                "SELECT id, title, status, priority, due_date, description FROM tasks ORDER BY due_date NULLS LAST LIMIT 10");
        model.addAttribute("recentTasks", rawTasks.stream().map(TaskRow::new).collect(Collectors.toList()));

        return "dashboard";
    }

    private long count(String sql) {
        Long result = jdbcTemplate.queryForObject(sql, Long.class);
        return result != null ? result : 0L;
    }

    // ===================== Task List =====================

    @GetMapping("/list")
    public String list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String priority,
            @RequestParam(required = false, defaultValue = "id") String sort,
            Model model) {

        StringBuilder sql = new StringBuilder(
                "SELECT id, title, description, status, priority, due_date, created_at FROM tasks WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            sql.append(" AND title ILIKE ?");
            params.add("%" + search.trim() + "%");
        }
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            params.add(status.trim());
        }
        if (priority != null && !priority.isBlank()) {
            sql.append(" AND priority = ?");
            params.add(priority.trim());
        }

        // Whitelist sort columns
        String safeSort = List.of("id", "due_date", "priority", "status").contains(sort) ? sort : "id";
        if ("priority".equals(safeSort)) {
            sql.append(" ORDER BY CASE priority WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END");
        } else if ("due_date".equals(safeSort)) {
            sql.append(" ORDER BY due_date NULLS LAST");
        } else {
            sql.append(" ORDER BY ").append(safeSort);
        }

        List<Map<String, Object>> rawTasks = jdbcTemplate.queryForList(sql.toString(), params.toArray());
        model.addAttribute("tasks", rawTasks.stream().map(TaskRow::new).collect(Collectors.toList()));
        return "list";
    }

    // ===================== Task Detail =====================

    @GetMapping("/detail/{id}")
    public String detail(@PathVariable int id, Model model) {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT id, title, description, status, priority, due_date, created_at, updated_at FROM tasks WHERE id = ?", id);
        if (rows.isEmpty()) {
            model.addAttribute("error", "タスクが見つかりませんでした。id=" + id);
            return "detail";
        }
        model.addAttribute("task", new TaskRow(rows.get(0)));
        return "detail";
    }

    // ===================== Task CRUD =====================

    @GetMapping("/tasks/new")
    public String newTaskForm(Model model) {
        model.addAttribute("isEdit", false);
        model.addAttribute("task", null);
        return "task-form";
    }

    @PostMapping("/tasks/new")
    public String createTask(
            @RequestParam String title,
            @RequestParam(required = false) String description,
            @RequestParam(defaultValue = "TODO") String status,
            @RequestParam(defaultValue = "MEDIUM") String priority,
            @RequestParam(required = false) String due_date,
            RedirectAttributes redirectAttributes) {

        if (title == null || title.isBlank()) {
            redirectAttributes.addFlashAttribute("error", "タイトルは必須です。");
            return "redirect:/tasks/new";
        }

        String sql = "INSERT INTO tasks (title, description, status, priority, due_date) VALUES (?, ?, ?, ?, ?)";
        jdbcTemplate.update(sql, title.trim(),
                description != null && !description.isBlank() ? description.trim() : null,
                status, priority,
                due_date != null && !due_date.isBlank() ? java.sql.Date.valueOf(due_date) : null);

        redirectAttributes.addFlashAttribute("message", "タスクを追加しました。");
        return "redirect:/list";
    }

    @GetMapping("/tasks/edit/{id}")
    public String editTaskForm(@PathVariable int id, Model model) {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT id, title, description, status, priority, due_date FROM tasks WHERE id = ?", id);
        if (rows.isEmpty()) {
            return "redirect:/list";
        }
        model.addAttribute("isEdit", true);
        model.addAttribute("task", new TaskRow(rows.get(0)));
        return "task-form";
    }

    @PostMapping("/tasks/edit/{id}")
    public String updateTask(
            @PathVariable int id,
            @RequestParam String title,
            @RequestParam(required = false) String description,
            @RequestParam String status,
            @RequestParam String priority,
            @RequestParam(required = false) String due_date,
            RedirectAttributes redirectAttributes) {

        if (title == null || title.isBlank()) {
            redirectAttributes.addFlashAttribute("error", "タイトルは必須です。");
            return "redirect:/tasks/edit/" + id;
        }

        String sql = "UPDATE tasks SET title=?, description=?, status=?, priority=?, due_date=?, updated_at=CURRENT_TIMESTAMP WHERE id=?";
        jdbcTemplate.update(sql, title.trim(),
                description != null && !description.isBlank() ? description.trim() : null,
                status, priority,
                due_date != null && !due_date.isBlank() ? java.sql.Date.valueOf(due_date) : null,
                id);

        redirectAttributes.addFlashAttribute("message", "タスクを更新しました。");
        return "redirect:/detail/" + id;
    }

    @PostMapping("/tasks/delete/{id}")
    public String deleteTask(@PathVariable int id, RedirectAttributes redirectAttributes) {
        jdbcTemplate.update("DELETE FROM tasks WHERE id = ?", id);
        redirectAttributes.addFlashAttribute("message", "タスクを削除しました。");
        return "redirect:/list";
    }

    // ===================== CSV Export =====================

    @GetMapping("/list/export")
    public ResponseEntity<byte[]> exportCsv() {
        List<Map<String, Object>> tasks = jdbcTemplate.queryForList(
                "SELECT id, title, description, status, priority, due_date, created_at FROM tasks ORDER BY id");

        StringBuilder csv = new StringBuilder();
        csv.append("ID,タイトル,説明,ステータス,優先度,期限,作成日時\n");
        for (Map<String, Object> task : tasks) {
            csv.append(escapeCsv(task.get("id")))
               .append(",").append(escapeCsv(task.get("title")))
               .append(",").append(escapeCsv(task.get("description")))
               .append(",").append(escapeCsv(task.get("status")))
               .append(",").append(escapeCsv(task.get("priority")))
               .append(",").append(escapeCsv(task.get("due_date")))
               .append(",").append(escapeCsv(task.get("created_at")))
               .append("\n");
        }

        byte[] bytes = csv.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"tasks.csv\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(bytes);
    }

    private String escapeCsv(Object value) {
        if (value == null) return "";
        String s = value.toString();
        if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    // ===================== SQL Console =====================

    @GetMapping("/query")
    public String query(Model model) {
        model.addAttribute("schemaTables", getSchemaInfo());
        return "index";
    }

    @PostMapping("/execute")
    public String execute(
            @RequestParam String query,
            @RequestParam(defaultValue = "index") String returnPage,
            HttpServletRequest request,
            Model model) {

        long startTime = System.nanoTime();
        String outcome;
        boolean isSelect = false;
        List<Map<String, Object>> selectResults = null;

        try {
            String q = query.trim();
            if (q.toLowerCase().startsWith("select") || q.toLowerCase().startsWith("explain")) {
                isSelect = true;
                List<Map<String, Object>> results = jdbcTemplate.queryForList(q);
                selectResults = results;
                model.addAttribute("results", results);
                if (!results.isEmpty()) {
                    model.addAttribute("columns", results.get(0).keySet());
                }
                outcome = "SELECT: " + results.size() + " 行取得";
            } else {
                int rows = jdbcTemplate.update(q);
                model.addAttribute("message", rows + " 行更新されました。");
                outcome = "更新: " + rows + " 行";
            }
        } catch (Exception e) {
            model.addAttribute("error", "SQLエラー: " + e.getMessage());
            outcome = "エラー: " + e.getMessage();
        }

        long endTime = System.nanoTime();
        double executionTimeMs = (endTime - startTime) / 1_000_000.0;
        model.addAttribute("executionTime", String.format("%.2f", executionTimeMs) + " ms");
        model.addAttribute("previousQuery", query);

        // Persist history to DB
        saveHistory(query, outcome, executionTimeMs);

        String targetPage = normalizeTargetPage(returnPage, request);

        if ("list".equals(targetPage)) {
            if (isSelect) {
                model.addAttribute("tasks", selectResults != null
                        ? selectResults.stream().map(TaskRow::new).collect(Collectors.toList())
                        : Collections.emptyList());
            } else {
                loadTasksToModel(model, null, null, null, "id");
            }
            return "list";
        }
        if ("history".equals(targetPage)) {
            model.addAttribute("history", loadHistory(null, null));
            return "history";
        }

        // Default: index (SQL Console)
        model.addAttribute("schemaTables", getSchemaInfo());
        return "index";
    }

    private String normalizeTargetPage(String returnPage, HttpServletRequest request) {
        if (returnPage != null) {
            String normalized = returnPage.trim().toLowerCase();
            if (List.of("list", "history", "index").contains(normalized)) return normalized;
        }
        String referer = request.getHeader("Referer");
        if (referer != null) {
            if (referer.contains("/list"))    return "list";
            if (referer.contains("/history")) return "history";
        }
        return "index";
    }

    // ===================== SQL History =====================

    @GetMapping("/history")
    public String history(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String outcome,
            Model model) {
        model.addAttribute("history", loadHistory(search, outcome));
        return "history";
    }

    @PostMapping("/history/clear")
    public String clearHistory(RedirectAttributes redirectAttributes) {
        jdbcTemplate.update("DELETE FROM sql_history");
        redirectAttributes.addFlashAttribute("message", "履歴を全削除しました。");
        return "redirect:/history";
    }

    private List<SqlHistoryEntry> loadHistory(String search, String outcomeFilter) {
        StringBuilder sql = new StringBuilder(
                "SELECT executed_at, query, outcome, execution_time_ms FROM sql_history WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.isBlank()) {
            sql.append(" AND query ILIKE ?");
            params.add("%" + search.trim() + "%");
        }
        if (outcomeFilter != null && !outcomeFilter.isBlank()) {
            sql.append(" AND outcome ILIKE ?");
            params.add(outcomeFilter.trim() + "%");
        }
        sql.append(" ORDER BY executed_at DESC LIMIT 100");

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql.toString(), params.toArray());
        List<SqlHistoryEntry> entries = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            String executedAt = row.get("executed_at") != null
                    ? row.get("executed_at").toString() : "";
            String q = (String) row.get("query");
            String out = (String) row.get("outcome");
            double ms = row.get("execution_time_ms") != null
                    ? ((Number) row.get("execution_time_ms")).doubleValue() : 0.0;
            entries.add(new SqlHistoryEntry(executedAt, q, out, ms));
        }
        return entries;
    }

    private void saveHistory(String query, String outcome, double executionTimeMs) {
        try {
            jdbcTemplate.update(
                    "INSERT INTO sql_history (query, outcome, execution_time_ms) VALUES (?, ?, ?)",
                    query, outcome, executionTimeMs);
        } catch (Exception ignored) {
            // History save failure should not break the main flow
        }
    }

    // ===================== Schema Viewer =====================

    @GetMapping("/schema")
    public String schema(Model model) {
        model.addAttribute("schemaTables", getSchemaInfo());
        return "schema";
    }

    private List<TableInfo> getSchemaInfo() {
        List<Map<String, Object>> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables " +
                "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' " +
                "ORDER BY table_name");

        List<TableInfo> result = new ArrayList<>();
        for (Map<String, Object> tbl : tables) {
            String tableName = (String) tbl.get("table_name");
            List<Map<String, Object>> cols = jdbcTemplate.queryForList(
                    "SELECT column_name, data_type, is_nullable, column_default " +
                    "FROM information_schema.columns " +
                    "WHERE table_schema = 'public' AND table_name = ? " +
                    "ORDER BY ordinal_position", tableName);

            List<ColumnInfo> columns = new ArrayList<>();
            for (Map<String, Object> col : cols) {
                columns.add(new ColumnInfo(
                        (String) col.get("column_name"),
                        (String) col.get("data_type"),
                        "YES".equals(col.get("is_nullable")),
                        col.get("column_default") != null ? col.get("column_default").toString() : null
                ));
            }
            result.add(new TableInfo(tableName, columns));
        }
        return result;
    }

    // ===================== Helpers =====================

    private void loadTasksToModel(Model model, String search, String status, String priority, String sort) {
        StringBuilder sql = new StringBuilder(
                "SELECT id, title, description, status, priority, due_date, created_at FROM tasks WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (search != null && !search.isBlank()) {
            sql.append(" AND title ILIKE ?"); params.add("%" + search.trim() + "%");
        }
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?"); params.add(status.trim());
        }
        if (priority != null && !priority.isBlank()) {
            sql.append(" AND priority = ?"); params.add(priority.trim());
        }
        String safeSort = List.of("id", "due_date", "priority", "status").contains(sort) ? sort : "id";
        sql.append(" ORDER BY ").append(safeSort);

        List<Map<String, Object>> rawTasks = jdbcTemplate.queryForList(sql.toString(), params.toArray());
        model.addAttribute("tasks", rawTasks.stream().map(TaskRow::new).collect(Collectors.toList()));
    }
}
