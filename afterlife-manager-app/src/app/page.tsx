"use client";

import { useEffect, useMemo, useState } from "react";
import type { CSSProperties, ElementType } from "react";
import {
  Activity,
  AlertCircle,
  BarChart3,
  CheckCircle2,
  Cloud,
  Copy,
  Database,
  Download,
  FileText,
  Landmark,
  Loader2,
  LockKeyhole,
  Play,
  Search,
  ShieldCheck,
  Sparkles,
  TableProperties,
  Users,
  Workflow,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

type QueryItem = {
  id: number;
  title: string;
  description: string;
  query: string;
};

type QueryRow = Record<string, string | number | boolean | null | Date>;

type QueryResult = {
  columns: string[];
  data: QueryRow[];
};

type MetricCard = {
  label: string;
  value: string;
  detail: string;
  icon: ElementType;
};

const queryMeta: Record<number, { category: string; icon: ElementType; accent: string }> = {
  1: { category: "Estate Overview", icon: Users, accent: "#38bdf8" },
  2: { category: "Financial Risk", icon: Landmark, accent: "#22c55e" },
  3: { category: "Transfer Ops", icon: Workflow, accent: "#f97316" },
  4: { category: "Beneficiaries", icon: ShieldCheck, accent: "#a855f7" },
  6: { category: "Events", icon: Activity, accent: "#ef4444" },
  9: { category: "Assets", icon: Cloud, accent: "#14b8a6" },
  14: { category: "Executive Summary", icon: BarChart3, accent: "#eab308" },
};

const overviewCards: MetricCard[] = [
  {
    label: "Core entities",
    value: "13",
    detail: "Users, assets, beneficiaries, triggers, logs, and authorities",
    icon: Database,
  },
  {
    label: "Demo queries",
    value: "7",
    detail: "Prepared analytics that run directly against SQL Server",
    icon: TableProperties,
  },
  {
    label: "Access model",
    value: "Policy led",
    detail: "Beneficiary permissions, legal validation, and audit history",
    icon: LockKeyhole,
  },
  {
    label: "Client view",
    value: "Live",
    detail: "Readable results, instant charts, export, and copy actions",
    icon: Sparkles,
  },
];

const formatValue = (value: QueryRow[string]) => {
  if (value === null || value === undefined) return "NULL";
  if (value instanceof Date) return value.toLocaleString();
  if (typeof value === "number") {
    return Number.isInteger(value) ? value.toLocaleString() : value.toLocaleString(undefined, { maximumFractionDigits: 2 });
  }
  return String(value);
};

const escapeCsv = (value: QueryRow[string]) => `"${formatValue(value).replaceAll('"', '""')}"`;

export default function Dashboard() {
  const [queries, setQueries] = useState<QueryItem[]>([]);
  const [selectedQuery, setSelectedQuery] = useState<QueryItem | null>(null);
  const [queryResult, setQueryResult] = useState<QueryResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState("All");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/queries")
      .then((res) => res.json())
      .then((data: { queries?: QueryItem[] }) => {
        if (data.queries) {
          setQueries(data.queries);
          setSelectedQuery(data.queries[0] ?? null);
        }
      })
      .catch(() => setError("Could not load the query catalog. Make sure the Next.js API route is running."));
  }, []);

  const categories = useMemo(() => {
    const allCategories = queries.map((query) => queryMeta[query.id]?.category ?? "General");
    return ["All", ...Array.from(new Set(allCategories))];
  }, [queries]);

  const filteredQueries = useMemo(() => {
    const term = search.toLowerCase().trim();
    return queries.filter((query) => {
      const category = queryMeta[query.id]?.category ?? "General";
      const matchesCategory = activeCategory === "All" || category === activeCategory;
      const matchesSearch = !term || `${query.title} ${query.description} ${category}`.toLowerCase().includes(term);
      return matchesCategory && matchesSearch;
    });
  }, [activeCategory, queries, search]);

  const chartConfig = useMemo(() => {
    if (!queryResult?.data.length) return null;

    const numericColumn = queryResult.columns.find((column) =>
      queryResult.data.some((row) => typeof row[column] === "number")
    );
    const labelColumn = queryResult.columns.find((column) => column !== numericColumn) ?? queryResult.columns[0];

    if (!numericColumn || !labelColumn) return null;

    return {
      labelColumn,
      numericColumn,
      data: queryResult.data.slice(0, 8).map((row) => ({
        label: formatValue(row[labelColumn]).slice(0, 18),
        value: Number(row[numericColumn] ?? 0),
      })),
    };
  }, [queryResult]);

  const runQuery = async (queryId: number) => {
    setLoading(true);
    setError(null);
    setQueryResult(null);

    try {
      const res = await fetch(`/api/queries?id=${queryId}`);
      const data = await res.json();

      if (res.ok) {
        setQueryResult({ columns: data.columns ?? [], data: data.data ?? [] });
      } else {
        setError(data.error || "Failed to execute query. Check the database connection and SQL Server service.");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "An unexpected error occurred while running the query.");
    } finally {
      setLoading(false);
    }
  };

  const copyQuery = async () => {
    if (!selectedQuery) return;
    await navigator.clipboard.writeText(selectedQuery.query);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1600);
  };

  const exportCsv = () => {
    if (!queryResult) return;
    const csv = [
      queryResult.columns.map(escapeCsv).join(","),
      ...queryResult.data.map((row) => queryResult.columns.map((column) => escapeCsv(row[column])).join(",")),
    ].join("\n");

    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `${selectedQuery?.title.replace(/\s+/g, "-").toLowerCase() || "query-results"}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  };

  const selectedMeta = selectedQuery ? queryMeta[selectedQuery.id] : null;

  return (
    <main className="app-shell">
      <section className="hero">
        <div className="hero-copy">
          <div className="status-pill">
            <span className="status-dot" />
            SQL Server full-stack demo
          </div>
          <h1>Digital Afterlife Manager</h1>
          <p>
            A polished client dashboard for auditing digital estates, transfer readiness, beneficiaries,
            trigger events, and financial assets from one live database interface.
          </p>
        </div>
        <div className="hero-actions">
          <button className="btn btn-secondary" type="button" onClick={copyQuery} disabled={!selectedQuery}>
            {copied ? <CheckCircle2 size={18} /> : <Copy size={18} />}
            {copied ? "Copied" : "Copy SQL"}
          </button>
          <button
            className="btn"
            type="button"
            onClick={() => selectedQuery && runQuery(selectedQuery.id)}
            disabled={!selectedQuery || loading}
          >
            {loading ? <Loader2 size={18} className="animate-spin" /> : <Play size={18} fill="currentColor" />}
            Run selected
          </button>
        </div>
      </section>

      <section className="metrics-grid" aria-label="Dashboard overview">
        {overviewCards.map((card) => {
          const Icon = card.icon;
          return (
            <article className="metric-card" key={card.label}>
              <div className="metric-icon">
                <Icon size={21} />
              </div>
              <div>
                <span>{card.label}</span>
                <strong>{card.value}</strong>
                <p>{card.detail}</p>
              </div>
            </article>
          );
        })}
      </section>

      <section className="workspace-grid">
        <aside className="sidebar-panel">
          <div className="panel-heading">
            <div>
              <span className="eyebrow">Query catalog</span>
              <h2>Analytics library</h2>
            </div>
            <TableProperties size={22} />
          </div>

          <label className="search-box">
            <Search size={18} />
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search reports"
              type="search"
            />
          </label>

          <div className="chip-row" aria-label="Query categories">
            {categories.map((category) => (
              <button
                className={category === activeCategory ? "chip active" : "chip"}
                key={category}
                type="button"
                onClick={() => setActiveCategory(category)}
              >
                {category}
              </button>
            ))}
          </div>

          <div className="query-list">
            {filteredQueries.map((query) => {
              const meta = queryMeta[query.id] ?? queryMeta[1];
              const Icon = meta.icon;
              const isActive = selectedQuery?.id === query.id;
              return (
                <button
                  className={isActive ? "query-card active" : "query-card"}
                  key={query.id}
                  type="button"
                  onClick={() => {
                    setSelectedQuery(query);
                    setQueryResult(null);
                    setError(null);
                  }}
                  style={{ "--accent": meta.accent } as CSSProperties}
                >
                  <span className="query-icon">
                    <Icon size={18} />
                  </span>
                  <span className="query-text">
                    <span className="query-category">{meta.category}</span>
                    <strong>{query.title}</strong>
                    <small>{query.description}</small>
                  </span>
                </button>
              );
            })}
          </div>
        </aside>

        <section className="content-panel">
          {selectedQuery ? (
            <>
              <div className="selected-header">
                <div>
                  <span className="eyebrow">{selectedMeta?.category ?? "General"}</span>
                  <h2>{selectedQuery.title}</h2>
                  <p>{selectedQuery.description}</p>
                </div>
                <button className="btn" type="button" onClick={() => runQuery(selectedQuery.id)} disabled={loading}>
                  {loading ? <Loader2 size={18} className="animate-spin" /> : <Play size={18} fill="currentColor" />}
                  Execute
                </button>
              </div>

              <div className="sql-card">
                <div className="sql-card-header">
                  <span>
                    <FileText size={16} />
                    SQL preview
                  </span>
                  <button className="icon-btn" type="button" onClick={copyQuery} aria-label="Copy SQL">
                    {copied ? <CheckCircle2 size={17} /> : <Copy size={17} />}
                  </button>
                </div>
                <pre>{selectedQuery.query}</pre>
              </div>
            </>
          ) : (
            <div className="empty-state">
              <Database size={42} />
              <h2>Select a report</h2>
              <p>Choose a query from the catalog to preview SQL, execute it, chart the result, and export rows.</p>
            </div>
          )}

          {loading && (
            <div className="loading-panel">
              <Loader2 size={26} className="animate-spin" />
              <span>Running query against SQL Server...</span>
            </div>
          )}

          {error && (
            <div className="alert-panel">
              <AlertCircle size={22} />
              <div>
                <strong>Query could not be completed</strong>
                <p>{error}</p>
              </div>
            </div>
          )}

          {queryResult && !loading && !error && (
            <div className="results-panel">
              <div className="results-header">
                <div>
                  <span className="eyebrow">Live result</span>
                  <h2>{queryResult.data.length} rows returned</h2>
                </div>
                <button className="btn btn-secondary" type="button" onClick={exportCsv} disabled={!queryResult.data.length}>
                  <Download size={18} />
                  Export CSV
                </button>
              </div>

              {chartConfig && (
                <div className="chart-panel">
                  <div>
                    <span className="eyebrow">Quick visual</span>
                    <h3>
                      {chartConfig.numericColumn} by {chartConfig.labelColumn}
                    </h3>
                  </div>
                  <ResponsiveContainer width="100%" height={240}>
                    <BarChart data={chartConfig.data} margin={{ top: 14, right: 8, left: 0, bottom: 0 }}>
                      <CartesianGrid stroke="rgba(148, 163, 184, 0.18)" vertical={false} />
                      <XAxis dataKey="label" stroke="#94a3b8" tickLine={false} axisLine={false} fontSize={12} />
                      <YAxis stroke="#94a3b8" tickLine={false} axisLine={false} fontSize={12} />
                      <Tooltip
                        cursor={{ fill: "rgba(56, 189, 248, 0.08)" }}
                        contentStyle={{
                          background: "#101827",
                          border: "1px solid rgba(148, 163, 184, 0.22)",
                          borderRadius: 8,
                          color: "#f8fafc",
                        }}
                      />
                      <Bar dataKey="value" fill="#38bdf8" radius={[6, 6, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}

              {queryResult.data.length > 0 ? (
                <div className="table-shell">
                  <table>
                    <thead>
                      <tr>
                        {queryResult.columns.map((column) => (
                          <th key={column}>{column}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {queryResult.data.map((row, rowIndex) => (
                        <tr key={`${selectedQuery?.id}-${rowIndex}`}>
                          {queryResult.columns.map((column) => (
                            <td key={column}>
                              {row[column] === null || row[column] === undefined ? (
                                <span className="null-value">NULL</span>
                              ) : (
                                formatValue(row[column])
                              )}
                            </td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="empty-state compact">
                  <CheckCircle2 size={34} />
                  <h3>Query executed successfully</h3>
                  <p>No records matched this report.</p>
                </div>
              )}
            </div>
          )}
        </section>
      </section>
    </main>
  );
}
