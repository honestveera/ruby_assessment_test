class User < ApplicationRecord
  KINDS = { 'student' => 0, 'teacher' => 1, 'student and teacher' => 2 }

  validate :validations_kinds, on: :update

  has_many :enrollments

  def self.kinds
    KINDS
  end

  def self.classmates(user)
    enrollments = user.enrollments
    program_ids = enrollments.map(&:program_id)
    return [] unless program_ids.present?

    user_ids = Enrollment.where(program_id: program_ids).map(&:user_id)
    return [] unless user_ids.present?

    where(id: user_ids.uniq.excluding(user.id))
  end

  def teachers
    Enrollment.where(user_id: id)
  end

  def student?
    kind == 0
  end

  def teacher?
    kind == 1
  end

  def validations_kinds
    return unless kind_changed?

    errors.add(:kind, 'Kind can not be teacher because is studying in at least one program') if student_kind_flag
    errors.add(:kind, 'Kind can not be student because is teaching in at least one program') if teacher_kind_flag
  end

  def student_kind_flag
    kind_change[0] == KINDS['student'] &&
      kind_change[1] == KINDS['teacher'] &&
      Enrollment.where(user_id: id).count > 0
  end

  def teacher_kind_flag
    kind_change[0] == KINDS['teacher'] &&
      kind_change[1] == KINDS['student'] &&
      Enrollment.where(teacher_id: id).count > 0
  end
end
