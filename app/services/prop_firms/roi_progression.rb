module PropFirms
  class RoiProgression
    def self.call(user:, from: nil, to: nil)
      transactions = user.prop_transactions.order(transaction_date: :asc)
      transactions = transactions.where("transaction_date >= ?", from) if from.present?
      transactions = transactions.where("transaction_date <= ?", to) if to.present?

      # Usar arreglos acumulados si no hay transacciones para modo demo
      if transactions.empty?
        # Referencia visual exacta: 29 jun -> Ingresos: $3,900, Gastos: $889, Retorno: $2,911
        ingresos_demo = [200, 250, 250, 250, 280, 2300, 3900, 4100, 4050, 4200, 4150, 5400]
        gastos_demo   = [200, 380, 420, 650, 1050,  900,  889, 1100, 1450, 1550, 1600, 1600]
        retorno_demo  = ingresos_demo.zip(gastos_demo).map { |i, g| i - g }

        return {
          labels: ["23 feb","02 mar","12 mar","25 mar","14 abr","08 may","12 jun","26 jun","29 jun","01 jul","06 jul","10 jul"],
          ingresos: ingresos_demo,
          gastos:   gastos_demo,
          retorno:  retorno_demo
        }
      end

      meses = %w[ene feb mar abr may jun jul ago sep oct nov dic]

      labels = []
      ingresos = []
      gastos = []
      retorno = []

      # Agrupar por fecha
      grouped = transactions.group_by { |t| t.transaction_date.to_date }

      # Si solo hay 1 fecha de transacciones, creamos punto de origen baseline para dibujar la línea
      if grouped.keys.size == 1
        first_date = grouped.keys.first
        prev_date = first_date - 1.day
        labels << "#{prev_date.day.to_s.rjust(2, '0')} #{meses[prev_date.month - 1]}"
        ingresos << 0
        gastos << 0
        retorno << 0
      end

      acum_ingresos = 0
      acum_gastos = 0

      grouped.each do |date, txs|
        dia = date.day.to_s.rjust(2, '0')
        mes = meses[date.month - 1]
        labels << "#{dia} #{mes}"

        ingreso_dia = txs.select { |t| t.transaction_type == 'payout' }.sum { |t| t.amount.to_f }
        gasto_dia   = txs.select { |t| t.transaction_type == 'expense' }.sum { |t| t.amount.to_f }

        acum_ingresos += ingreso_dia
        acum_gastos   += gasto_dia

        ingresos << acum_ingresos
        gastos   << acum_gastos
        retorno  << (acum_ingresos - acum_gastos)
      end

      { labels: labels, ingresos: ingresos, gastos: gastos, retorno: retorno }
    end
  end
end
