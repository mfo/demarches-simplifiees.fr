# frozen_string_literal: true

class Cron::Datagouv::UserWithProConnectByMonthJob < Cron::Datagouv::BaseJob
  self.schedule_expression = "every month at 3:30"
  HEADERS = ["mois", "nb_usagers_crees", "nb_instructeurs_crees", "nb_administrateurs_crees", "nb_usagers_convertis", "nb_instructeurs_convertis", "nb_administrateurs_convertis"]
  FILE_NAME = 'nb_utilisateurs_avec_pro_connect_par_mois'
  RESOURCE = '4f00b392-be6a-4c93-84f3-ee5819b5daa4'

  def perform
    super(RESOURCE, HEADERS, FILE_NAME)
  end

  private

  def data_for(month:)
    administrateurs_on_pro_connect = Administrateur
      .joins("INNER JOIN agent_connect_informations ON agent_connect_informations.user_id = administrateurs.user_id")
      .where(agent_connect_informations: { created_at: month.all_month })
      .distinct

    administrateurs_on_pro_connect_count = administrateurs_on_pro_connect.count

    new_administrateurs_through_pro_connect_count = administrateurs_on_pro_connect
      .where(administrateurs: { created_at: month.all_month })
      .count

    administrateurs_convert_to_pro_connect_count = administrateurs_on_pro_connect_count - new_administrateurs_through_pro_connect_count

    instructeurs_on_pro_connect = Instructeur
      .joins("INNER JOIN agent_connect_informations ON agent_connect_informations.user_id = instructeurs.user_id")
      .where(agent_connect_informations: { created_at: month.all_month })
      .left_joins(user: :administrateur)
      .where(administrateurs: { id: nil })
      .distinct

    instructeurs_on_pro_connect_count = instructeurs_on_pro_connect.count

    new_instructeurs_through_pro_connect_count = instructeurs_on_pro_connect
      .where(instructeurs: { created_at: month.all_month })
      .count

    instructeurs_convert_to_pro_connect_count = instructeurs_on_pro_connect_count - new_instructeurs_through_pro_connect_count

    users_on_pro_connect = User
      .joins("INNER JOIN agent_connect_informations ON agent_connect_informations.user_id = users.id")
      .where(agent_connect_informations: { created_at: month.all_month })
      .where.missing(:instructeur)
      .distinct

    users_on_pro_connect_count = users_on_pro_connect.count

    new_users_through_pro_connect_count = users_on_pro_connect
      .where(users: { created_at: month.all_month })
      .count

    users_convert_to_pro_connect_count = users_on_pro_connect_count - new_users_through_pro_connect_count

    [
      month.strftime(DATE_FORMAT),
      new_users_through_pro_connect_count,
      new_instructeurs_through_pro_connect_count,
      new_administrateurs_through_pro_connect_count,
      users_convert_to_pro_connect_count,
      instructeurs_convert_to_pro_connect_count,
      administrateurs_convert_to_pro_connect_count,
    ]
  end
end
