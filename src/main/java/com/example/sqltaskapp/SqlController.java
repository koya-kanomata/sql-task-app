package com.example.sqltaskapp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@Controller
public class SqlController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/list")
    public String list(Model model) {
        String sql = "SELECT id, title, status, due_date FROM tasks ORDER BY id";
        List<Map<String, Object>> tasks = jdbcTemplate.queryForList(sql);
        model.addAttribute("tasks", tasks);
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
    public String execute(@RequestParam String query, Model model) {
        long startTime = System.nanoTime(); // より精密にナノ秒で計測
        try {
            String q = query.trim();
            if (q.toLowerCase().startsWith("select")) {
                List<Map<String, Object>> results = jdbcTemplate.queryForList(q);
                model.addAttribute("results", results);
                if (!results.isEmpty()) {
                    model.addAttribute("columns", results.get(0).keySet());
                }
            } else {
                int rows = jdbcTemplate.update(q);
                model.addAttribute("message", rows + " 行更新されました。");
            }
        } catch (Exception e) {
            model.addAttribute("error", "SQLエラー: " + e.getMessage());
        }

        long endTime = System.nanoTime();
        double executionTimeMs = (endTime - startTime) / 1_000_000.0;
        model.addAttribute("executionTime", String.format("%.2f", executionTimeMs) + " ms");
        model.addAttribute("previousQuery", query);
        return "index";
    }
}