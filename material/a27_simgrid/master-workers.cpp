/* Mestre-trabalhadores em SimGrid S4U (aula 27).
 * Adaptado do tutorial oficial "Master-Workers" (simgrid.org/doc/latest/Tutorial_Algorithms.html).
 *
 * Uso: ./master-workers <plataforma.xml> <rr|ondemand> <nworkers> <ntasks>
 *                       <flops_medio> <bytes_por_tarefa> <cv> <semente>
 * Saída (stdout, uma linha CSV):
 *   strategy,workers,tasks,flops,bytes,cv,seed,simtime,walltime
 */
#include <simgrid/s4u.hpp>
#include <chrono>
#include <cstdio>
#include <random>
#include <string>
#include <vector>

namespace sg4 = simgrid::s4u;
XBT_LOG_NEW_DEFAULT_CATEGORY(mw, "Mestre-trabalhadores (aula 27)");

static std::string strategy;
static long n_tasks;
static double flops_mean, bytes_per_task, cv;
static unsigned seed;

/* Custo de cada tarefa: constante (cv = 0) ou Gamma com média flops_mean e
 * coeficiente de variação cv (forma 1/cv^2, escala flops_mean*cv^2). */
static std::vector<double> draw_costs()
{
  std::vector<double> costs(n_tasks, flops_mean);
  if (cv > 0) {
    std::mt19937 gen(seed);
    std::gamma_distribution<double> g(1.0 / (cv * cv), flops_mean * cv * cv);
    for (auto& c : costs)
      c = g(gen);
  }
  return costs;
}

/* Mestre "round-robin": empurra a tarefa i para o trabalhador i mod W. */
static void master_rr(std::vector<sg4::Mailbox*> workers)
{
  auto costs = draw_costs();
  for (long i = 0; i < n_tasks; i++)
    workers[i % workers.size()]->put(new double(costs[i]), bytes_per_task);
  for (auto* mb : workers) /* fim: custo negativo */
    mb->put(new double(-1.0), 0);
}

/* Mestre "sob demanda": responde a quem pedir trabalho. */
static void master_ondemand(std::vector<sg4::Mailbox*> workers)
{
  auto costs = draw_costs();
  sg4::Mailbox* me = sg4::Mailbox::by_name("master");
  for (long i = 0; i < n_tasks; i++) {
    auto who = me->get_unique<int>();
    workers[*who]->put(new double(costs[i]), bytes_per_task);
  }
  for (size_t k = 0; k < workers.size(); k++) {
    auto who = me->get_unique<int>();
    workers[*who]->put(new double(-1.0), 0);
  }
}

static void worker(int id)
{
  sg4::Mailbox* mine   = sg4::Mailbox::by_name("w-" + std::to_string(id));
  sg4::Mailbox* master = sg4::Mailbox::by_name("master");
  for (;;) {
    if (strategy == "ondemand")
      master->put(new int(id), 64); /* pedido de trabalho: 64 bytes */
    auto cost = mine->get_unique<double>();
    if (*cost < 0)
      break;
    sg4::this_actor::execute(*cost); /* "computa" *cost flops */
  }
}

int main(int argc, char* argv[])
{
  sg4::Engine e(&argc, argv);
  xbt_assert(argc == 9, "Uso: %s plat.xml rr|ondemand W N flops bytes cv seed", argv[0]);
  strategy       = argv[2];
  int W          = std::stoi(argv[3]);
  n_tasks        = std::stol(argv[4]);
  flops_mean     = std::stod(argv[5]);
  bytes_per_task = std::stod(argv[6]);
  cv             = std::stod(argv[7]);
  seed           = std::stoul(argv[8]);

  e.load_platform(argv[1]);

  std::vector<sg4::Mailbox*> mbs;
  for (int i = 0; i < W; i++) {
    mbs.push_back(sg4::Mailbox::by_name("w-" + std::to_string(i)));
    e.host_by_name("node-" + std::to_string(i))->add_actor("worker", worker, i);
  }
  if (strategy == "rr")
    e.host_by_name("master")->add_actor("master", master_rr, mbs);
  else
    e.host_by_name("master")->add_actor("master", master_ondemand, mbs);

  auto t0 = std::chrono::steady_clock::now();
  e.run();
  double wall = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

  printf("%s,%d,%ld,%g,%g,%g,%u,%.6f,%.6f\n", strategy.c_str(), W, n_tasks, flops_mean, bytes_per_task, cv, seed,
         sg4::Engine::get_clock(), wall);
  return 0;
}
