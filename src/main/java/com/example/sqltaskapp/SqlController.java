package com.example.sqltaskapp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.HttpServletRequest;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;

@Controller
public class SqlController {

    private static final String HISTORY_SESSION_KEY = "sqlHistory";
    private static final int HISTORY_LIMIT = 20;
    private static final DateTimeFormatter HISTORY_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

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

        public String getExecutedAt() {
            return executedAt;
        }

        public String getQuery() {
            return query;
        }

        public String getOutcome() {
            return outcome;
        }

        public double getExecutionTimeMs() {
            return executionTimeMs;
        }

        public String getExecutionTime() {
            return String.format("%.2f ms", executionTimeMs);
        }
    }

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/")
    public String home(Model model) {
        loadTasks(model);
        return "list";
    }

    @GetMapping("/query")
    public String query() {
        return "index";
    }

    @GetMapping("/history")
    public String history(HttpSession session, Model model) {
        model.addAttribute("history", getHistory(session));
        return "history";
    }

    @GetMapping("/list")
    public String list(Model model) {
        loadTasks(model);
        return "list";
    }

    @GetMapping("/detail/{id}")
    public String detail(@PathVariable int id, Model model) {
        String sql = "SELECT id, title, status, due_date FROM tasks WHERE id = ?";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, id);

        if (rows.isEmpty()) {
            model.addAttribute("error", "タスクが見つかりませんでした。id=" + id);
            return "detail";
        }

        model.addAttribute("task", rows.get(0));
        return "detail";
    }

    @PostMapping("/execute")
    public String execute(
            @RequestParam String query,
            @RequestParam(defaultValue = "index") String returnPage,
            HttpServletRequest request,
            HttpSession session,
            Model model
    ) {
        long startTime = System.nanoTime(); // より精密にナノ秒で計測
        String outcome;
        boolean isSelect = false;
        List<Map<String, Object>> selectResults = null;
        try {
            String q = query.trim();
            if (q.toLowerCase().startsWith("select")) {
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

        addHistory(session, query, outcome, executionTimeMs);

        String targetPage = normalizeTargetPage(returnPage, request);

        if ("list".equals(targetPage)) {
            if (isSelect) {
                model.addAttribute("tasks", selectResults);
            } else {
                loadTasks(model);
            }
            return "list";
        }
        if ("history".equals(targetPage)) {
            model.addAttribute("history", getHistory(session));
            return "history";
        }
        return "index";
    }

    private String normalizeTargetPage(String returnPage, HttpServletRequest request) {
        if (returnPage != null) {
            String normalized = returnPage.trim().toLowerCase();
            if ("list".equals(normalized) || "history".equals(normalized) || "index".equals(normalized)) {
                return normalized;
            }
        }

        String referer = request.getHeader("Referer");
        if (referer != null) {
            if (referer.contains("/list")) {
                return "list";
            }
            if (referer.contains("/history")) {
                return "history";
            }
        }
        return "index";
    }

    private void loadTasks(Model model) {
        String sql = "SELECT id, title, status, due_date FROM tasks ORDER BY id";
        List<Map<String, Object>> tasks = jdbcTemplate.queryForList(sql);
        model.addAttribute("tasks", tasks);
    }

    @SuppressWarnings("unchecked")
    private List<SqlHistoryEntry> getHistory(HttpSession session) {
        Object value = session.getAttribute(HISTORY_SESSION_KEY);
        if (value instanceof List<?>) {
            return (List<SqlHistoryEntry>) value;
        }

        List<SqlHistoryEntry> history = new ArrayList<>();
        session.setAttribute(HISTORY_SESSION_KEY, history);
        return history;
    }

    private void addHistory(HttpSession session, String query, String outcome, double executionTimeMs) {
        List<SqlHistoryEntry> history = getHistory(session);
        history.add(0, new SqlHistoryEntry(
                LocalDateTime.now().format(HISTORY_FORMATTER),
                query,
                outcome,
                executionTimeMs
        ));

        if (history.size() > HISTORY_LIMIT) {
            history.subList(HISTORY_LIMIT, history.size()).clear();
        }
    }
}